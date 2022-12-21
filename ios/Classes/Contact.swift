import Contacts

@available(iOS 9.0, *)
struct Contact {
    var id: String = ""
    var displayName: String = ""
    var phones: [ContactPhone] = []
    var emails: [ContactEmail] = []
    var structuredName: StructuredName?
    var organization: Organization?

    init(fromContact contact: CNContact) {
        id = contact.identifier
        displayName = "\(contact.givenName) \(contact.familyName)"
        phones = contact.phoneNumbers.map { ContactPhone(fromPhoneNumber: $0) }
        emails = contact.emailAddresses.map { ContactEmail(fromEmail: $0) }
        structuredName = StructuredName(fromContact: contact)
        organization = Organization(fromContact: contact)
    }

    func toMap() -> [String: Any?] {
        [
            "id": id,
            "displayName": displayName,
            "phones": phones.map { $0.toMap() },
            "emails": emails.map { $0.toMap() },
            "structuredName": structuredName?.toMap(),
            "organization": organization?.toMap(),
        ]
    }
}

struct ContactPhone {
    var number: String = ""
    var label: String = ""

    init(fromPhoneNumber phone: CNLabeledValue<CNPhoneNumber>) {
        number = phone.value.stringValue
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

    init(fromEmail email: CNLabeledValue<NSString>) {
        address = email.value as String
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

    func toMap() -> [String: Any] {
        [
            "address": address,
            "label": label,
        ]
    }
}

struct StructuredName {
    var namePrefix: String = ""
    var givenName: String = ""
    var middleName: String = ""
    var familyName: String = ""
    var nameSuffix: String = ""

    init(fromContact contact: CNContact) {
        namePrefix = contact.namePrefix
        givenName = contact.givenName
        middleName = contact.middleName
        familyName = contact.familyName
        nameSuffix = contact.nameSuffix
    }

    func toMap() -> [String: Any] {
        [
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

    init(fromContact contact: CNContact) {
        company = contact.organizationName
        department = contact.departmentName
        jobDescription = contact.jobTitle
    }

    func toMap() -> [String: Any] {
        [
            "company": company,
            "department": department,
            "jobDescription": jobDescription,
        ]
    }
}