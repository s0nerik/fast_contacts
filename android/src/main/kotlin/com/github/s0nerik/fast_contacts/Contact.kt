package com.github.s0nerik.fast_contacts

data class Contact(
        var id: String,
        var displayName: String,
        var phones: List<String>,
        var emails: List<String>
) {
    fun asMap() = mapOf(
            "id" to id,
            "displayName" to displayName,
            "phones" to phones,
            "emails" to emails
    )

    companion object {
//        fun merge(contacts: List<Contact>): Contact {
//            var id = ""
//            var displayName = ""
//            var phones = emptyList<String>()
//            var emails = emptyList<String>()
//
//            for (c in contacts) {
//                if (id.isEmpty() && c.id.isNotEmpty()) {
//                    id = c.id
//                }
//                if (displayName.isEmpty() && c.displayName.isNotEmpty()) {
//                    displayName = c.displayName
//                }
//                if (phones.isEmpty() && c.phones.isNotEmpty()) {
//                    phones = c.phones
//                }
//                if (emails.isEmpty() && c.emails.isNotEmpty()) {
//                    emails = c.emails
//                }
//            }
//
//            return Contact(id, displayName, phones, emails)
//        }

        /**
         * Modifies the first Contact from the list in place.
         */
        fun mergeInPlace(contacts: List<Contact>): Contact {
            assert(contacts.isNotEmpty())

            val result = contacts.first()

            if (contacts.size == 1) {
                return result
            }

            for (c in contacts.listIterator(1)) {
                if (result.id.isEmpty() && c.id.isNotEmpty()) {
                    result.id = c.id
                }
                if (result.displayName.isEmpty() && c.displayName.isNotEmpty()) {
                    result.displayName = c.displayName
                }
                if (result.phones.isEmpty() && c.phones.isNotEmpty()) {
                    result.phones = c.phones
                }
                if (result.emails.isEmpty() && c.emails.isNotEmpty()) {
                    result.emails = c.emails
                }
            }

            return result
        }
    }
}