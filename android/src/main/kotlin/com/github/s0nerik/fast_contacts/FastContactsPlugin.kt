package com.github.s0nerik.fast_contacts

import android.content.ContentResolver
import android.content.ContentUris
import android.database.Cursor
import android.net.Uri
import android.os.Handler
import android.provider.ContactsContract
import android.provider.ContactsContract.CommonDataKinds.Phone
import android.provider.ContactsContract.CommonDataKinds.Email
import android.provider.ContactsContract.CommonDataKinds.Organization
import android.provider.ContactsContract.CommonDataKinds.StructuredName
import androidx.core.content.ContentResolverCompat
import androidx.lifecycle.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.util.concurrent.*

private enum class ContactField {
    // Name-related
    DISPLAY_NAME,
    NAME_PREFIX,
    GIVEN_NAME,
    MIDDLE_NAME,
    FAMILY_NAME,
    NAME_SUFFIX,

    // Organization-related
    COMPANY,
    DEPARTMENT,
    JOB_DESCRIPTION,

    // Phone-related
    PHONE_NUMBERS,
    PHONE_LABELS,

    // Email-related
    EMAIL_ADDRESSES,
    EMAIL_LABELS;

    fun toProjectionStrings(): Set<String> = when (this) {
        DISPLAY_NAME -> setOf(StructuredName.DISPLAY_NAME)
        NAME_PREFIX -> setOf(StructuredName.PREFIX)
        GIVEN_NAME -> setOf(StructuredName.GIVEN_NAME)
        MIDDLE_NAME -> setOf(StructuredName.MIDDLE_NAME)
        FAMILY_NAME -> setOf(StructuredName.FAMILY_NAME)
        NAME_SUFFIX -> setOf(StructuredName.SUFFIX)
        COMPANY -> setOf(Organization.COMPANY)
        DEPARTMENT -> setOf(Organization.DEPARTMENT)
        JOB_DESCRIPTION -> setOf(Organization.TITLE)
        PHONE_NUMBERS -> setOf(Phone.NUMBER)
        PHONE_LABELS -> setOf(Phone.TYPE, Phone.LABEL)
        EMAIL_ADDRESSES -> setOf(Email.ADDRESS)
        EMAIL_LABELS -> setOf(Email.TYPE, Email.LABEL)
    }

    companion object {
        fun fromString(str: String) = when (str) {
            "displayName" -> DISPLAY_NAME
            "namePrefix" -> NAME_PREFIX
            "givenName" -> GIVEN_NAME
            "middleName" -> MIDDLE_NAME
            "familyName" -> FAMILY_NAME
            "nameSuffix" -> NAME_SUFFIX
            "company" -> COMPANY
            "department" -> DEPARTMENT
            "jobDescription" -> JOB_DESCRIPTION
            "phoneNumbers" -> PHONE_NUMBERS
            "phoneLabels" -> PHONE_LABELS
            "emailAddresses" -> EMAIL_ADDRESSES
            "emailLabels" -> EMAIL_LABELS
            else -> throw IllegalArgumentException("Unknown field: $str")
        }
    }
}

private enum class ContactPart {
    PHONES, EMAILS, STRUCTURED_NAME, ORGANIZATION;

    companion object {
        fun fromFields(fields: Set<ContactField>): Set<ContactPart> {
            return fields.map { field ->
                when (field) {
                    ContactField.DISPLAY_NAME,
                    ContactField.NAME_PREFIX,
                    ContactField.GIVEN_NAME,
                    ContactField.MIDDLE_NAME,
                    ContactField.FAMILY_NAME,
                    ContactField.NAME_SUFFIX -> STRUCTURED_NAME
                    ContactField.COMPANY,
                    ContactField.DEPARTMENT,
                    ContactField.JOB_DESCRIPTION -> ORGANIZATION
                    ContactField.PHONE_NUMBERS,
                    ContactField.PHONE_LABELS -> PHONES
                    ContactField.EMAIL_ADDRESSES,
                    ContactField.EMAIL_LABELS -> EMAILS
                }
            }.toSet()
        }
    }
}

/** FastContactsPlugin */
class FastContactsPlugin : FlutterPlugin, MethodCallHandler, LifecycleOwner, ViewModelStoreOwner {
    private lateinit var channel: MethodChannel
    private lateinit var contentResolver: ContentResolver
    private lateinit var handler: Handler

    private val allContactsExecutor = Executors.newSingleThreadExecutor()
    private val allContactsPartExecutors =
        ContactPart.values().associateWith { Executors.newSingleThreadExecutor() }

    private val imageExecutor = ThreadPoolExecutor(
        4, Integer.MAX_VALUE,
        20L, TimeUnit.SECONDS,
        SynchronousQueue(),
    )

    private var allContacts: List<Contact> = emptyList()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel =
            MethodChannel(flutterPluginBinding.binaryMessenger, "com.github.s0nerik.fast_contacts")
        handler = Handler(flutterPluginBinding.applicationContext.mainLooper)
        contentResolver = flutterPluginBinding.applicationContext.contentResolver
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "fetchAllContacts" -> {
                val args = call.arguments as Map<String, Any>
                val fieldStrings = args["fields"] as List<String>
                val fields = fieldStrings.map(ContactField::fromString).toSet()
                val contactParts = ContactPart.fromFields(fields)

                val partialContacts = ConcurrentHashMap<ContactPart, Collection<Contact>>()
                val fetchCompletionLatch = CountDownLatch(contactParts.size)
                contactParts.map { part ->
                    allContactsPartExecutors[part]!!.execute {
                        try {
                            val contacts = fetchPartialContacts(part, fields)
                            partialContacts[part] = contacts
                        } finally {
                            fetchCompletionLatch.countDown()
                        }
                    }
                }
                allContactsExecutor.execute {
                    fetchCompletionLatch.await()
                    withResultDispatcher(result) {
                        val mergedContacts = mutableMapOf<String, Contact>()
                        for (part in partialContacts.values.flatten()) {
                            val existing = mergedContacts[part.id]
                            if (existing == null) {
                                mergedContacts[part.id] = part
                            } else {
                                existing.mergeWith(part)
                            }
                        }
                        allContacts = mergedContacts.values.toList()
                        allContacts.size
                    }
                }
            }
            "getAllContactsPage" -> {
                val args = call.arguments as Map<String, Any>
                val from = args["from"] as Int
                val to = args["to"] as Int

                val page = allContacts.subList(from, to).map(Contact::asMap)
                result.success(page)
            }
            "clearFetchedContacts" -> {
                allContacts = emptyList()
                result.success(null)
            }
            "getContactImage" -> {
                val args = call.arguments as Map<String, String>
                val contactId = args.getValue("id").toLong()
                if (args["size"] == "thumbnail") {
                    imageExecutor.execute {
                        withResultDispatcher(result) { getContactThumbnail(contactId) }
                    }
                } else {
                    imageExecutor.execute {
                        withResultDispatcher(result) { getContactImage(contactId) }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun getLifecycle(): Lifecycle {
        val registry = LifecycleRegistry(this)
        registry.currentState = Lifecycle.State.RESUMED
        return registry
    }

    override fun getViewModelStore(): ViewModelStore {
        return ViewModelStore()
    }

    private fun fetchPartialContacts(
        part: ContactPart,
        fields: Set<ContactField>
    ): Collection<Contact> {
        return when (part) {
            ContactPart.PHONES -> readPhonesInfo(fields)
            ContactPart.EMAILS -> readEmailsInfo(fields)
            ContactPart.STRUCTURED_NAME -> readStructuredNameInfo(fields)
            ContactPart.ORGANIZATION -> readOrganizationInfo(fields)
        }.values
    }

    private fun readStructuredNameInfo(fields: Set<ContactField>): Map<Long, Contact> {
        val contacts = mutableMapOf<Long, Contact>()
        readTargetInfo(ContactPart.STRUCTURED_NAME, fields) { cursor ->
            val contactId = cursor.getLong(StructuredName.CONTACT_ID)!!
            contacts[contactId] = Contact(
                id = contactId.toString(),
                structuredName = StructuredName(
                    displayName = cursor.getString(StructuredName.DISPLAY_NAME) ?: "",
                    namePrefix = cursor.getString(StructuredName.PREFIX) ?: "",
                    givenName = cursor.getString(StructuredName.GIVEN_NAME) ?: "",
                    middleName = cursor.getString(StructuredName.MIDDLE_NAME) ?: "",
                    familyName = cursor.getString(StructuredName.FAMILY_NAME) ?: "",
                    nameSuffix = cursor.getString(StructuredName.SUFFIX) ?: "",
                ),
            )
        }
        return contacts
    }

    private fun readPhonesInfo(fields: Set<ContactField>): Map<Long, Contact> {
        val contacts = mutableMapOf<Long, Contact>()
        readTargetInfo(ContactPart.PHONES, fields) { cursor ->
            val contactId = cursor.getLong(Phone.CONTACT_ID)!!
            val contactPhone = ContactPhone(
                number = cursor.getString(Phone.NUMBER) ?: "",
                label = cursor.getString(Phone.LABEL)
                    ?: cursor.getInt(Phone.TYPE)?.let(::getPhoneLabel)
                    ?: "",
            )

            if (contacts.containsKey(contactId)) {
                (contacts[contactId]!!.phones as MutableList<ContactPhone>).add(contactPhone)
            } else {
                contacts[contactId] = Contact(
                    id = contactId.toString(),
                    phones = mutableListOf(contactPhone),
                )
            }
        }
        return contacts
    }

    private fun getPhoneLabel(type: Int): String {
        return when (type) {
            Phone.TYPE_ASSISTANT -> "assistant"
            Phone.TYPE_CALLBACK -> "callback"
            Phone.TYPE_CAR -> "car"
            Phone.TYPE_COMPANY_MAIN -> "companyMain"
            Phone.TYPE_FAX_HOME -> "faxHome"
            Phone.TYPE_FAX_WORK -> "faxWork"
            Phone.TYPE_HOME -> "home"
            Phone.TYPE_ISDN -> "isdn"
            Phone.TYPE_MAIN -> "main"
            Phone.TYPE_MMS -> "mms"
            Phone.TYPE_MOBILE -> "mobile"
            Phone.TYPE_OTHER -> "other"
            Phone.TYPE_OTHER_FAX -> "faxOther"
            Phone.TYPE_PAGER -> "pager"
            Phone.TYPE_RADIO -> "radio"
            Phone.TYPE_TELEX -> "telex"
            Phone.TYPE_TTY_TDD -> "ttyTtd"
            Phone.TYPE_WORK -> "work"
            Phone.TYPE_WORK_MOBILE -> "workMobile"
            Phone.TYPE_WORK_PAGER -> "workPager"
            Phone.TYPE_CUSTOM -> "custom"
            else -> ""
        }
    }

    private fun readEmailsInfo(fields: Set<ContactField>): Map<Long, Contact> {
        val contacts = mutableMapOf<Long, Contact>()
        readTargetInfo(ContactPart.EMAILS, fields) { cursor ->
            val contactId = cursor.getLong(Email.CONTACT_ID)!!
            val contactEmail = ContactEmail(
                address = cursor.getString(Email.ADDRESS) ?: "",
                label = cursor.getString(Email.LABEL)
                    ?: cursor.getInt(Email.TYPE)?.let(::getEmailAddressLabel)
                    ?: "",
            )

            if (contacts.containsKey(contactId)) {
                (contacts[contactId]!!.emails as MutableList<ContactEmail>).add(contactEmail)
            } else {
                contacts[contactId] = Contact(
                    id = contactId.toString(),
                    emails = mutableListOf(contactEmail),
                )
            }
        }
        return contacts
    }

    private fun getEmailAddressLabel(type: Int): String {
        return when (type) {
            Email.TYPE_HOME -> "home"
            Email.TYPE_OTHER -> "other"
            Email.TYPE_WORK -> "work"
            Email.TYPE_CUSTOM -> "custom"
            else -> ""
        }
    }

    private fun readOrganizationInfo(fields: Set<ContactField>): Map<Long, Contact> {
        val contacts = mutableMapOf<Long, Contact>()
        readTargetInfo(ContactPart.ORGANIZATION, fields) { cursor ->
            val contactId = cursor.getLong(Organization.CONTACT_ID)!!
            contacts[contactId] = Contact(
                id = contactId.toString(),
                organization = Organization(
                    company = cursor.getString(Organization.COMPANY) ?: "",
                    department = cursor.getString(Organization.DEPARTMENT) ?: "",
                    jobDescription = cursor.getString(Organization.JOB_DESCRIPTION) ?: "",
                )
            )
        }
        return contacts
    }

    private fun readTargetInfo(
        targetInfo: ContactPart,
        fields: Set<ContactField>,
        onData: (cursor: Cursor) -> Unit
    ) {
        val fieldNames = fields.map { it.toProjectionStrings() }.flatten().toMutableList()
        fieldNames.add(0, CONTACT_ID_FIELDS[targetInfo]!!)
        val projection = fieldNames.toTypedArray()

        val cursor = ContentResolverCompat.query(
            contentResolver,
            CONTENT_URI[targetInfo],
            projection,
            SELECTION[targetInfo],
            SELECTION_ARGS[targetInfo],
            SORT_ORDER[targetInfo],
            null,
        )
        cursor?.use {
            while (!cursor.isClosed && cursor.moveToNext()) {
                onData(cursor)
            }
        }
    }

    private fun getContactThumbnail(contactId: Long): ByteArray? {
        val contactUri =
            ContentUris.withAppendedId(ContactsContract.Contacts.CONTENT_URI, contactId)
        return contentResolver.query(
            Uri.withAppendedPath(contactUri, ContactsContract.Contacts.Photo.CONTENT_DIRECTORY),
            arrayOf(ContactsContract.Contacts.Photo.PHOTO),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToNext()) cursor.getBlob(0) else null
        }
    }

    private fun getContactImage(contactId: Long): ByteArray? {
        val contactUri =
            ContentUris.withAppendedId(ContactsContract.Contacts.CONTENT_URI, contactId)
        val displayPhotoUri =
            Uri.withAppendedPath(contactUri, ContactsContract.Contacts.Photo.DISPLAY_PHOTO)

        return contentResolver.openAssetFileDescriptor(displayPhotoUri, "r")?.use { fd ->
            fd.createInputStream().use {
                it.readBytes()
            }
        }
    }

    private fun <T> withResultDispatcher(result: MethodChannel.Result, action: () -> T) {
        try {
            val resultValue = action()
            handler.post {
                result.success(resultValue)
            }
        } catch (e: Exception) {
            handler.post {
                result.error("", e.localizedMessage, e.toString())
            }
        }
    }

    companion object {
        private val CONTENT_URI = mapOf(
            ContactPart.PHONES to Phone.CONTENT_URI,
            ContactPart.EMAILS to Email.CONTENT_URI,
            ContactPart.STRUCTURED_NAME to ContactsContract.Data.CONTENT_URI,
            ContactPart.ORGANIZATION to ContactsContract.Data.CONTENT_URI,
        )
        private val CONTACT_ID_FIELDS = mapOf(
            ContactPart.PHONES to Phone.CONTACT_ID,
            ContactPart.EMAILS to Email.CONTACT_ID,
            ContactPart.STRUCTURED_NAME to StructuredName.CONTACT_ID,
            ContactPart.ORGANIZATION to Organization.CONTACT_ID,
        )
        private val PROJECTION = mapOf(
            ContactPart.PHONES to arrayOf(
                Phone.NUMBER,
                Phone.TYPE,
                Phone.LABEL,
            ),
            ContactPart.EMAILS to arrayOf(
                Email.ADDRESS,
                Email.TYPE,
                Email.LABEL,
            ),
            ContactPart.STRUCTURED_NAME to arrayOf(
                StructuredName.DISPLAY_NAME,
                StructuredName.PREFIX,
                StructuredName.GIVEN_NAME,
                StructuredName.MIDDLE_NAME,
                StructuredName.FAMILY_NAME,
                StructuredName.SUFFIX,
            ),
            ContactPart.ORGANIZATION to arrayOf(
                Organization.COMPANY,
                Organization.DEPARTMENT,
                Organization.JOB_DESCRIPTION,
            ),
        )
        private val SELECTION = mapOf(
            ContactPart.PHONES to "${Phone.MIMETYPE} = ?",
            ContactPart.EMAILS to "${Email.MIMETYPE} = ?",
            ContactPart.STRUCTURED_NAME to "${StructuredName.MIMETYPE} = ?",
            ContactPart.ORGANIZATION to "${Organization.MIMETYPE} = ?",
        )
        private val SELECTION_ARGS = mapOf(
            ContactPart.PHONES to arrayOf(Phone.CONTENT_ITEM_TYPE),
            ContactPart.EMAILS to arrayOf(Email.CONTENT_ITEM_TYPE),
            ContactPart.STRUCTURED_NAME to arrayOf(StructuredName.CONTENT_ITEM_TYPE),
            ContactPart.ORGANIZATION to arrayOf(Organization.CONTENT_ITEM_TYPE),
        )
        private val SORT_ORDER = mapOf(
            ContactPart.PHONES to "${Phone.CONTACT_ID} ASC",
            ContactPart.EMAILS to "${Email.CONTACT_ID} ASC",
            ContactPart.STRUCTURED_NAME to "${StructuredName.CONTACT_ID} ASC",
            ContactPart.ORGANIZATION to "${Organization.CONTACT_ID} ASC",
        )
    }
}

fun Cursor.getString(col: String): String? {
    val index = getColumnIndex(col)
    if (index < 0) {
        return null
    }
    return getString(index)
}

fun Cursor.getInt(col: String): Int? {
    val index = getColumnIndex(col)
    if (index < 0) {
        return null
    }
    return getInt(index)
}

fun Cursor.getLong(col: String): Long? {
    val index = getColumnIndex(col)
    if (index < 0) {
        return null
    }
    return getLong(index)
}