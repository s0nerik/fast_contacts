import Contacts

@available(iOS 9.0, *)
struct Contact {
    var id: String = ""
    var phones: [ContactPhone] = []
    var emails: [ContactEmail] = []
    var structuredName: StructuredName?
    var organization: Organization?

    init(fromContact contact: CNContact, fields: Set<ContactField>) {
        id = contact.identifier
        if (fields.contains(ContactField.phoneNumbers)
            || fields.contains(ContactField.phoneLabels)) {
            phones = [ContactPhone](contact.phoneNumbers.map { ContactPhone(fromPhoneNumber: $0, fields: fields) })
        }
        if (fields.contains(ContactField.emailAddresses)
            || fields.contains(ContactField.emailLabels)) {
            emails = [ContactEmail](contact.emailAddresses.map { ContactEmail(fromEmail: $0, fields: fields) })
        }
        if (fields.contains(ContactField.displayName)
            || fields.contains(ContactField.namePrefix)
            || fields.contains(ContactField.givenName)
            || fields.contains(ContactField.middleName)
            || fields.contains(ContactField.familyName)
            || fields.contains(ContactField.nameSuffix)) {
            structuredName = StructuredName(fromContact: contact, fields: fields)
        }
        if (fields.contains(ContactField.company)
            || fields.contains(ContactField.department)
            || fields.contains(ContactField.jobDescription)) {
            organization = Organization(fromContact: contact, fields: fields)
        }
    }

    func toMap() -> [String: Any] {
        [
            "id": id,
            "phones": phones.map { $0.toMap() },
            "emails": emails.map { $0.toMap() },
            "structuredName": structuredName?.toMap() ?? NSNull(),
            "organization": organization?.toMap() ?? NSNull(),
        ]
    }
}

struct ContactPhone {
    var number: String = ""
    var label: String = ""

    init(fromPhoneNumber phone: CNLabeledValue<CNPhoneNumber>, fields: Set<ContactField>) {
        if (fields.contains(ContactField.phoneNumbers)) {
            number = phone.value.stringValue
        }
        if (fields.contains(ContactField.phoneLabels)) {
            switch phone.label {
            case CNLabelPhoneNumberHomeFax:
                label = "faxHome"
            case CNLabelPhoneNumberOtherFax:
                label = "faxOther"
            case CNLabelPhoneNumberWorkFax:
                label = "faxWork"
            case CNLabelHome:
                label = "home"
            case CNLabelPhoneNumberiPhone:
                label = "iPhone"
            case CNLabelPhoneNumberMain:
                label = "main"
            case CNLabelPhoneNumberMobile:
                label = "mobile"
            case CNLabelPhoneNumberPager:
                label = "pager"
            case CNLabelWork:
                label = "work"
            case CNLabelOther:
                label = "other"
            default:
                if #available(iOS 13, *), phone.label == CNLabelSchool {
                    label = "school"
                } else {
                    label = phone.label ?? ""
                }
            }
        }
    }

    func toMap() -> [String: Any] {
        [
            "number": number,
            "label": label,
        ]
    }
}

struct ContactEmail {
    var address: String = ""
    var label: String = ""

    init(fromEmail email: CNLabeledValue<NSString>, fields: Set<ContactField>) {
        if (fields.contains(ContactField.emailAddresses)) {
            address = email.value as String
        }
        if (fields.contains(ContactField.emailLabels)) {
            switch email.label {
            case CNLabelHome:
                label = "home"
            case CNLabelEmailiCloud:
                label = "iCloud"
            case CNLabelWork:
                label = "work"
            case CNLabelOther:
                label = "other"
            default:
                if #available(iOS 13, *), email.label == CNLabelSchool {
                    label = "school"
                } else {
                    label = email.label ?? ""
                }
            }
        }
    }

    func toMap() -> [String: Any] {
        [
            "address": address,
            "label": label,
        ]
    }
}

struct StructuredName {
    var displayName: String = ""
    var namePrefix: String = ""
    var givenName: String = ""
    var middleName: String = ""
    var familyName: String = ""
    var nameSuffix: String = ""

    init(fromContact contact: CNContact, fields: Set<ContactField>) {
        if (fields.contains(ContactField.displayName)) {
            displayName = "\(contact.givenName) \(contact.familyName)"
            if (displayName == " ") {
                displayName = ""
            }
        }
        if (fields.contains(ContactField.namePrefix)) {
            namePrefix = contact.namePrefix
        }
        if (fields.contains(ContactField.givenName)) {
            givenName = contact.givenName
        }
        if (fields.contains(ContactField.middleName)) {
            middleName = contact.middleName
        }
        if (fields.contains(ContactField.familyName)) {
            familyName = contact.familyName
        }
        if (fields.contains(ContactField.nameSuffix)) {
            nameSuffix = contact.nameSuffix
        }
    }

    func toMap() -> [String: Any] {
        [
            "displayName": displayName,
            "namePrefix": namePrefix,
            "givenName": givenName,
            "middleName": middleName,
            "familyName": familyName,
            "nameSuffix": nameSuffix,
        ]
    }
}

struct Organization {
    var company: String = ""
    var department: String = ""
    var jobDescription: String = ""

    init(fromContact contact: CNContact, fields: Set<ContactField>) {
        if (fields.contains(ContactField.company)) {
            company = contact.organizationName
        }
        if (fields.contains(ContactField.department)) {
            department = contact.departmentName
        }
        if (fields.contains(ContactField.jobDescription)) {
            jobDescription = contact.jobTitle
        }
    }

    func toMap() -> [String: Any] {
        [
            "company": company,
            "department": department,
            "jobDescription": jobDescription,
        ]
    }
}
