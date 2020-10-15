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
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getContacts":
            DispatchQueue.global().async {
                let contacts = self.getContacts()
                DispatchQueue.main.async {
                    result(contacts)
                }
            }
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
    
    private func getContacts() -> Array<Dictionary<String, Any>> {
        let contactStore = CNContactStore()
        let keys = [CNContactPhoneNumbersKey, CNContactFamilyNameKey, CNContactGivenNameKey, CNContactNicknameKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = CNContactSortOrder.givenName
        
        var result = [Dictionary<String, Any>]()
        try? contactStore.enumerateContacts(with: request) { (contact, cursor) in
            result.append([
                "id": contact.identifier,
                "displayName": "\(contact.givenName) \(contact.familyName)",
                "phones": contact.phoneNumbers.map { (p) in p.value.stringValue },
            ])
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
