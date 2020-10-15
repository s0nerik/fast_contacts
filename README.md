# fast_contacts

A **much** faster alternative to [contacts_service](https://pub.dev/packages/contacts_service) and [flutter_contact](https://pub.dev/packages/flutter_contact) for reading the device's contact book.

This plugin uses recommended approaches on both platforms to achieve optimal query performance.

# Usage

To use this plugin, add `fast_contacts` as a [dependency in your `pubspec.yaml` file](https://flutter.io/platform-plugins/).

## Permissions  
### Android  
Add the following permission to your AndroidManifest.xml:  

```xml  
<uses-permission android:name="android.permission.READ_CONTACTS" />  
```

### iOS
Set the `NSContactsUsageDescription` in your `Info.plist` file  
  
```xml  
<key>NSContactsUsageDescription</key>  
<string>Description of why you need the contacts permission.</string>  
```  

**Note**
`fast_contacts` doesn't handle permissions. Use special plugins (like [permission_handler](https://pub.dartlang.org/packages/permission_handler)) to ask for the permission before accessing contacts.

## Example

```dart
// Import package  
import 'package:fast_contacts/fast_contacts.dart';  

// Get all contacts
final contacts = await FastContacts.allContacts;

// Get first contact's image (thumbnail)
final thumbnail = await FastContacts.getContactImage(contacts[0].id);

// Get first contact's image (full size)
final thumbnail = await FastContacts.getContactImage(contacts[0].id, size: ContactImageSize.fullSize);
```

For a more complete usage example, see `example` project.

## Limitations

* Currently, only basic contact info (id, displayName, phones) is fetched for each contact. A custom projection support is planned for the future (PR's are welcome!).

## Performance

![Android: Samsung Galaxy S8](docs/images/galaxy_s8_screenshot.jpg)

![iOS: iPhone 8](docs/images/iphone_8_screenshot.jpg)