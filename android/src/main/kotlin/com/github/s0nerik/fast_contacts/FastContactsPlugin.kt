package com.github.s0nerik.fast_contacts

import android.content.ContentUris
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.os.AsyncTask
import android.os.Bundle
import android.os.Handler
import android.provider.ContactsContract
import android.provider.ContactsContract.CommonDataKinds.Phone
import androidx.annotation.NonNull
import androidx.lifecycle.*
import androidx.loader.app.LoaderManager
import androidx.loader.content.CursorLoader
import androidx.loader.content.Loader
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.IOException
import java.util.concurrent.Executors


/** FastContactsPlugin */
class FastContactsPlugin : FlutterPlugin, MethodCallHandler, LifecycleOwner, ViewModelStoreOwner {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    private lateinit var context: Context

    private val fullSizeImageExecutor = Executors.newCachedThreadPool()

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.github.s0nerik.fast_contacts")
        context = flutterPluginBinding.applicationContext
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getContacts" -> {
                ContactsLoader(
                        context = oldRegistar?.activeContext() ?: context,
                        plugin = this,
                        onResult = { result.success(it.map(Contact::asMap)) },
                        onError = {
                            result.error("", it.localizedMessage, it.toString())
                        }
                ).load()
            }
            "getContactImage" -> {
                val args = call.arguments as Map<String, String>
                val contactId = args.getValue("id").toLong()
                if (args["size"] == "thumbnail") {
                    ContactThumbnailImageLoader(
                            context = oldRegistar?.activeContext() ?: context,
                            plugin = this,
                            contactId = contactId,
                            onResult = { result.success(it) },
                            onError = {
                                result.error("", it.localizedMessage, it.toString())
                            }
                    ).load()
                } else {
                    ContactImageLoaderAsyncTask(
                            context = oldRegistar?.activeContext() ?: context,
                            contactId = contactId,
                            onResult = { result.success(it) },
                            onError = {
                                result.error("", it.localizedMessage, it.toString())
                            }
                    ).executeOnExecutor(fullSizeImageExecutor)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
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

    // This static function is optional and equivalent to onAttachedToEngine. It supports the old
    // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
    // plugin registration via this function while apps migrate to use the new Android APIs
    // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
    //
    // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
    // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
    // depending on the user's project. onAttachedToEngine or registerWith must both be defined
    // in the same class.
    companion object {
        private var oldRegistar: PluginRegistry.Registrar? = null

        @JvmStatic
        fun registerWith(registrar: PluginRegistry.Registrar) {
            oldRegistar = registrar
            val channel = MethodChannel(registrar.messenger(), "com.github.s0nerik.fast_contacts")
            channel.setMethodCallHandler(FastContactsPlugin())
        }
    }
}

private class ContactsLoader(
        private val context: Context,
        private val plugin: FastContactsPlugin,
        private val onResult: (Collection<Contact>) -> Unit,
        private val onError: (Exception) -> Unit
) : LoaderManager.LoaderCallbacks<Cursor> {
    fun load() {
        LoaderManager.getInstance(plugin).initLoader(0, null, this)
    }

    override fun onCreateLoader(id: Int, args: Bundle?) = CursorLoader(
            context,
            Phone.CONTENT_URI,
            PROJECTION_LIST,
            null,
            null,
            "${Phone.DISPLAY_NAME} ASC"
    )

    override fun onLoadFinished(loader: Loader<Cursor>, data: Cursor?) {
        try {
            val contacts = mutableMapOf<Long, Contact>()
            data?.use {
                while (!data.isClosed && data.moveToNext()) {
                    val contactId: Long = data.getLong(PROJECTION_LIST.indexOf(Phone.CONTACT_ID))
                    val displayName: String = data.getString(PROJECTION_LIST.indexOf(Phone.DISPLAY_NAME))
                            ?: ""
                    val phone: String = data.getString(PROJECTION_LIST.indexOf(Phone.NUMBER)) ?: ""

                    if (contacts.containsKey(contactId)) {
                        (contacts[contactId]!!.phones as MutableList<String>).add(phone)
                    } else {
                        contacts[contactId] = Contact(
                                id = contactId.toString(),
                                displayName = displayName,
                                phones = mutableListOf(phone)
                        )
                    }
                }
            }
            onResult(contacts.values)
        } catch (e: Exception) {
            onError(e)
        }
    }

    override fun onLoaderReset(loader: Loader<Cursor>) {}

    companion object {
        private val PROJECTION_LIST = arrayOf(
                Phone.CONTACT_ID,
                Phone.DISPLAY_NAME,
                Phone.NUMBER
        )
    }
}

private class ContactThumbnailImageLoader(
        private val context: Context,
        private val plugin: FastContactsPlugin,
        private val contactId: Long,
        private val onResult: (ByteArray?) -> Unit,
        private val onError: (Exception) -> Unit
) : LoaderManager.LoaderCallbacks<Cursor> {
    fun load() {
        LoaderManager.getInstance(plugin).initLoader(1, null, this)
    }

    override fun onCreateLoader(id: Int, args: Bundle?): CursorLoader {
        val contactUri = ContentUris.withAppendedId(ContactsContract.Contacts.CONTENT_URI, contactId)
        return CursorLoader(
                context,
                Uri.withAppendedPath(contactUri, ContactsContract.Contacts.Photo.CONTENT_DIRECTORY),
                arrayOf(ContactsContract.Contacts.Photo.PHOTO),
                null,
                null,
                null
        )
    }

    override fun onLoadFinished(loader: Loader<Cursor>, data: Cursor?) {
        try {
            if (data == null) {
                onResult(null)
            } else {
                data.use {
                    if (data.moveToNext()) {
                        val bytes = data.getBlob(0)
                        onResult(bytes)
                    } else {
                        onResult(null)
                    }
                }
            }
        } catch (e: Exception) {
            onError(e)
        }
    }

    override fun onLoaderReset(loader: Loader<Cursor>) {}
}

private class ContactImageLoaderAsyncTask(
        private val context: Context,
        private val contactId: Long,
        private val onResult: (ByteArray?) -> Unit,
        private val onError: (Exception) -> Unit
) : AsyncTask<Void, Void, Unit>() {
    override fun doInBackground(vararg params: Void?) {
        val contactUri = ContentUris.withAppendedId(ContactsContract.Contacts.CONTENT_URI, contactId)
        val displayPhotoUri = Uri.withAppendedPath(contactUri, ContactsContract.Contacts.Photo.DISPLAY_PHOTO)
        try {
            val fd = context.contentResolver.openAssetFileDescriptor(displayPhotoUri, "r")
            if (fd != null) {
                fd.use {
                    fd.createInputStream().use {
                        val result = it.readBytes()
                        Handler(context.mainLooper).post {
                            onResult(result)
                        }
                    }
                }
            } else {
                Handler(context.mainLooper).post {
                    onResult(null)
                }
            }
        } catch (e: IOException) {
            Handler(context.mainLooper).post {
                onError(e)
            }
        }
    }
}