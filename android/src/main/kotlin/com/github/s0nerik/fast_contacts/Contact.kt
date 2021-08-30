package com.github.s0nerik.fast_contacts

data class Contact(
        val id: String,
        val displayName: String,
        val phones: List<String> = emptyList(),
        val emails: List<String> = emptyList(),
        val structuredName: StructuredName? = null
) {
    fun asMap() = mapOf(
            "id" to id,
            "displayName" to displayName,
            "phones" to phones,
            "emails" to emails,
            "structuredName" to structuredName?.asMap()
    )
}

data class StructuredName(
        val namePrefix: String,
        val givenName: String,
        val middleName: String,
        val familyName: String,
        val nameSuffix: String
) {
    fun asMap() = mapOf(
            "namePrefix" to namePrefix,
            "givenName" to givenName,
            "middleName" to middleName,
            "familyName" to familyName,
            "nameSuffix" to nameSuffix
    )
}