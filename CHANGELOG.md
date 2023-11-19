## 3.1.0

- Added `getContact()` method to fetch a single contact by ID
- Implemented `hashCode`, `==`, `toString()`, `toMap()`, `fromMap()` for `Contact` and its parts

## 3.0.4

- AGP 8.0 support

## 3.0.3

- Added some documentation

## 3.0.2

- Fixed `dart:typed_data` import issue for old Flutter versions

## 3.0.1

- "fix non_type_as_type_argument for Uint8List" by @dadagov125

## 3.0.0

- Added ability to select which fields to fetch. Fewer fields == faster
- Decoding no longer hangs UI isolate on huge contact lists

## 2.0.0

- "Add labels for Email & Phone for Android & IOS" by @PcolBP

## 1.2.0

- "Add organization fields" by @arjenfvellinga

## 1.1.1

- Updated Android build config

## 1.1.0

- Added `emails` and `structuredName` to Contact
- Refactored Android code to exclude AsyncTask usages

## 1.0.0

Null-safety support

## 0.1.0

Initial implementation. Pre-NNBD.