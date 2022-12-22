import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'model/contact.dart';
import 'util/map_merging.dart';

class _MutableContact implements Contact {
  _MutableContact({
    required this.id,
    required this.displayName,
    required this.phones,
    required this.emails,
    required this.structuredName,
    required this.organization,
  });

  factory _MutableContact.fromMap(Map map) => _MutableContact(
        id: map['id'] as String,
        displayName: map['displayName'] as String,
        phones:
            (map['phones'] as List).map((map) => Phone.fromMap(map)).toList(),
        emails:
            (map['emails'] as List).map((map) => Email.fromMap(map)).toList(),
        structuredName: map['structuredName'] != null
            ? StructuredName.fromMap(map['structuredName']!)
            : null,
        organization: map['organization'] != null
            ? Organization.fromMap(map['organization']!)
            : null,
      );

  @override
  String id;
  @override
  String displayName;
  @override
  List<Phone> phones;
  @override
  List<Email> emails;
  @override
  StructuredName? structuredName;
  @override
  Organization? organization;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MutableContact &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          phones == other.phones &&
          emails == other.emails &&
          structuredName == other.structuredName &&
          organization == other.organization;

  @override
  int get hashCode =>
      id.hashCode ^
      displayName.hashCode ^
      phones.hashCode ^
      emails.hashCode ^
      structuredName.hashCode ^
      organization.hashCode;
}

enum ContactImageSize {
  thumbnail,
  fullSize,
}

class FastContacts {
  static const MethodChannel _channel =
      const MethodChannel('com.github.s0nerik.fast_contacts');

  static Future<List<Contact>> getAllContacts() async {
    late final Iterable<Map> contactInfoParts;
    if (Platform.isAndroid) {
      final info = await Future.wait([
        _channel.invokeMethod<List>('getContacts', {
          'type': 'phones',
        }),
        _channel.invokeMethod<List>('getContacts', {
          'type': 'emails',
        }),
        _channel.invokeMethod<List>('getContacts', {
          'type': 'structuredName',
        }),
        _channel.invokeMethod<List>('getContacts', {
          'type': 'organization',
        }),
      ]);
      contactInfoParts = info.expand((e) => e ?? const []).cast<Map>();
    } else {
      final info = await _channel.invokeListMethod('getAllContacts');
      contactInfoParts = info?.cast<Map>() ?? const [];
    }

    final contacts = _mergeContactsInfo(contactInfoParts);
    return contacts;
  }

  static Future<Uint8List?> getContactImage(
    String contactId, {
    ContactImageSize size = ContactImageSize.thumbnail,
  }) =>
      _channel.invokeMethod('getContactImage', {
        'id': contactId,
        'size': size == ContactImageSize.thumbnail ? 'thumbnail' : 'fullSize',
      });
}

List<Contact> _mergeContactsInfo(
  Iterable<Map?> contactInfoParts,
) {
  final mergedContactsMap = <String, Map>{};
  for (final contact in contactInfoParts) {
    if (contact == null) continue;
    final id = contact['id'] as String?;
    if (id == null) continue;
    mergedContactsMap[id] ??= {};
    mergeMapValues(mergedContactsMap[id]!, contact);
  }

  final mergedContacts = <Contact>[];
  for (final contactMap in mergedContactsMap.values) {
    final contact = _MutableContact.fromMap(contactMap);
    mergedContacts.add(contact);
  }

  return mergedContacts;
}
