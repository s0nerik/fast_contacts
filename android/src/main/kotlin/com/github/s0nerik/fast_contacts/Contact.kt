package com.github.s0nerik.fast_contacts

data class Contact(
        val id: String,
        val displayName: String,
        val phones: List<String>
) {
    fun asMap() = mapOf(
            "id" to id,
            "displayName" to displayName,
            "phones" to phones
    )
}