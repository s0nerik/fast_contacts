import Flutter
import UIKit
import Contacts

@available(iOS 9.0, *)
public class SwiftFastContactsPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.github.s0nerik.fast_contacts", binaryMessenger: registrar.messenger())
        let instance = SwiftFastContactsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    private var allContacts = [Dictionary<String, Any?>]()

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "fetchAllContacts":
            DispatchQueue.global().async {
                let start = DispatchTime.now()

                let contacts = self.getContacts()

                let end = DispatchTime.now()
                let timeMillis = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
                
                self.allContacts = contacts
                DispatchQueue.main.async {
                    result([
                        "count": contacts.count,
                        "timeMillis": timeMillis,
                    ])
                }
            }
        case "getAllContactsPage":
            let args = call.arguments as! Dictionary<String, Int>
            let from = args["from"]!
            let to = args["to"]!

            let pageJson = Array(allContacts[from..<to])
            let compactedPageJson = compactJSON(pageJson)
            result(compactedPageJson)
        case "clearFetchedContacts":
            allContacts.removeAll()
            result(nil)
        case "getContactImage":
            let args = call.arguments as! Dictionary<String, String>
            let id = args["id"]!
            let size = args["size"]!

            DispatchQueue.global().async {
                do {
                    let data = try self.getContactImage(contactId: id, size: size)
                    DispatchQueue.main.async {
                        result(data)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError.init(code: "", message: error.localizedDescription, details: ""))
                    }
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getContacts() -> Array<Dictionary<String, Any?>> {
        let contactStore = CNContactStore()
        let keys = [
            // Phones
            CNContactPhoneNumbersKey,
            // Emails
            CNContactEmailAddressesKey,
            // Structured name
            CNContactNamePrefixKey,
            CNContactGivenNameKey,
            CNContactMiddleNameKey,
            CNContactFamilyNameKey,
            CNContactNameSuffixKey,
            // Work information
            CNContactOrganizationNameKey,
            CNContactDepartmentNameKey,
            CNContactJobTitleKey,
        ] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = CNContactSortOrder.givenName

        var result = [Dictionary<String, Any?>]()
        try? contactStore.enumerateContacts(with: request) { (contact, cursor) in
            result.append(
                Contact(fromContact: contact).toMap()
            )
        }
        return result
    }

    private func getContactImage(contactId: String, size: String) throws -> FlutterStandardTypedData? {
        let contactStore = CNContactStore()

        let contact = try contactStore.unifiedContact(
            withIdentifier: contactId,
            keysToFetch: size == "thumbnail"
                ? [CNContactThumbnailImageDataKey] as [CNKeyDescriptor]
                : [CNContactImageDataAvailableKey, CNContactImageDataKey] as [CNKeyDescriptor]
        )
        let data = size == "thumbnail"
            ? contact.thumbnailImageData
            : contact.imageData
        if let data = data {
            return FlutterStandardTypedData.init(bytes: data)
        }
        return nil
    }
}

// Returns compacted JSON value:
// - removes empty arrays
// - removes empty objects
// - removes null values
// - removes empty strings
private func compactJSON(_ json: Any) -> Any {
    switch json {
    case let dict as [String: Any]:
        var result = [String: Any]()
        for (key, value) in dict {
            let compactedValue = compactJSON(value)
            if compactedValue is NSNull {
                continue
            }
            result[key] = compactedValue
        }
        if (result.isEmpty) {
            return NSNull()
        }
        return result
    case let array as [Any]:
        return [Any](array.map(compactJSON).filter { $0 is NSNull == false })
    case let string as String:
        return string.isEmpty ? NSNull() : string
    default:
        return json
    }
}
