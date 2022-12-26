package com.github.s0nerik.fast_contacts

data class Contact(
    val id: String,
    var phones: List<ContactPhone> = emptyList(),
    var emails: List<ContactEmail> = emptyList(),
    var structuredName: StructuredName? = null,
    var organization: Organization? = null,
) {
    fun asMap(fields: Set<ContactField>): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>()
        map["id"] = id

        if (ContactField.PHONE_NUMBERS in fields
            || ContactField.PHONE_LABELS in fields) {
            map["phones"] = phones.map { it.asMap(fields = fields) }
        }
        if (ContactField.EMAIL_ADDRESSES in fields
            || ContactField.EMAIL_LABELS in fields) {
            map["emails"] = emails.map { it.asMap(fields = fields) }
        }
        if (ContactField.DISPLAY_NAME in fields
            || ContactField.FAMILY_NAME in fields
            || ContactField.GIVEN_NAME in fields
            || ContactField.MIDDLE_NAME in fields
            || ContactField.NAME_PREFIX in fields
            || ContactField.NAME_SUFFIX in fields) {
            map["structuredName"] = structuredName?.asMap(fields = fields)
        }
        if (ContactField.COMPANY in fields
            || ContactField.DEPARTMENT in fields
            || ContactField.JOB_DESCRIPTION in fields) {
            map["organization"] = organization?.asMap(fields = fields)
        }
        return map
    }

    fun mergeWith(other: Contact) {
        phones = if (phones.isEmpty() && other.phones.isNotEmpty()) other.phones else phones
        emails = if (emails.isEmpty() && other.emails.isNotEmpty()) other.emails else emails
        structuredName = structuredName ?: other.structuredName
        organization = organization ?: other.organization
    }
}

data class ContactPhone(
    val number: String,
    val label: String,
) {
    fun asMap(fields: Set<ContactField>): Map<String, String> {
        val map = mutableMapOf<String, String>()
        if (ContactField.PHONE_NUMBERS in fields) {
            map["number"] = number
        }
        if (ContactField.PHONE_LABELS in fields) {
            map["label"] = label
        }
        return map
    }
}

data class ContactEmail(
    val address: String,
    val label: String
) {
    fun asMap(fields: Set<ContactField>): Map<String, String> {
        val map = mutableMapOf<String, String>()
        if (ContactField.EMAIL_ADDRESSES in fields) {
            map["address"] = address
        }
        if (ContactField.EMAIL_LABELS in fields) {
            map["label"] = label
        }
        return map
    }
}

data class StructuredName(
    val displayName: String,
    val namePrefix: String,
    val givenName: String,
    val middleName: String,
    val familyName: String,
    val nameSuffix: String,
) {
    fun asMap(fields: Set<ContactField>): Map<String, String> {
        val map = mutableMapOf<String, String>()
        if (ContactField.DISPLAY_NAME in fields) {
            map["displayName"] = displayName
        }
        if (ContactField.NAME_PREFIX in fields) {
            map["namePrefix"] = namePrefix
        }
        if (ContactField.GIVEN_NAME in fields) {
            map["givenName"] = givenName
        }
        if (ContactField.MIDDLE_NAME in fields) {
            map["middleName"] = middleName
        }
        if (ContactField.FAMILY_NAME in fields) {
            map["familyName"] = familyName
        }
        if (ContactField.NAME_SUFFIX in fields) {
            map["nameSuffix"] = nameSuffix
        }
        return map
    }
}

data class Organization(
    val company: String,
    val department: String,
    val jobDescription: String,
) {
    fun asMap(fields: Set<ContactField>): Map<String, String> {
        val map = mutableMapOf<String, String>()
        if (ContactField.COMPANY in fields) {
            map["company"] = company
        }
        if (ContactField.DEPARTMENT in fields) {
            map["department"] = department
        }
        if (ContactField.JOB_DESCRIPTION in fields) {
            map["jobDescription"] = jobDescription
        }
        return map
    }
}
