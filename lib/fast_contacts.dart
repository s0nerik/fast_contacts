import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

abstract class Contact {
  String get id;
  String get displayName;
  List<String> get phones;
  List<String> get emails;
  StructuredName? get structuredName;
  Organization? get organization;
}

class StructuredName {
  StructuredName._({
    required this.namePrefix,
    required this.givenName,
    required this.middleName,
    required this.familyName,
    required this.nameSuffix,
  });

  static StructuredName? _fromMap(Map? map) {
    if (map == null) return null;
    return StructuredName._(
      namePrefix: map['namePrefix'] as String,
      givenName: map['givenName'] as String,
      middleName: map['middleName'] as String,
      familyName: map['familyName'] as String,
      nameSuffix: map['nameSuffix'] as String,
    );
  }

  final String namePrefix;
  final String givenName;
  final String middleName;
  final String familyName;
  final String nameSuffix;
}

class Organization {
  Organization._({
    required this.company,
    required this.department,
    required this.jobDescription,
  });

  static Organization? _fromMap(Map? map) {
    if (map == null) return null;
    return Organization._(
      company: map['company'] as String,
      department: map['department'] as String,
      jobDescription: map['jobDescription'] as String,
    );
  }

  final String company;
  final String department;
  final String jobDescription;
}

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
        phones: (map['phones'] as List).cast<String>(),
        emails: (map['emails'] as List).cast<String>(),
        structuredName: StructuredName._fromMap(map['structuredName']),
        organization: Organization._fromMap(map['organization']),
      );

  @override
  String id;
  @override
  String displayName;
  @override
  List<String> phones;
  @override
  List<String> emails;
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

  static Future<List<Contact>> get allContacts async {
    if (Platform.isAndroid) {
      return _allContactsAndroid;
    }

    final contacts = await _channel.invokeMethod<List>('getContacts');
    return contacts?.map((map) => _MutableContact.fromMap(map)).toList() ??
        const [];
  }

  static Future<List<Contact>> get _allContactsAndroid async {
    final specificInfoContacts = await Future.wait([
      _channel.invokeMethod<List>('getContacts', {
        'type': 'phones',
      }).then(_parseMutableContacts),
      _channel.invokeMethod<List>('getContacts', {
        'type': 'emails',
      }).then(_parseMutableContacts),
      _channel.invokeMethod<List>('getContacts', {
        'type': 'structuredName',
      }).then(_parseMutableContacts),
      _channel.invokeMethod<List>('getContacts', {
        'type': 'organization',
      }).then(_parseMutableContacts),
    ]);

    return _mergeContactsInfo(specificInfoContacts);
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

List<_MutableContact> _parseMutableContacts(List<dynamic>? contacts) {
  return contacts?.map((map) => _MutableContact.fromMap(map)).toList() ??
      const <_MutableContact>[];
}

List<Contact> _mergeContactsInfo(
  List<List<_MutableContact>> allContacts,
) {
  if (allContacts.length == 1) {
    return allContacts[0];
  }

  final mergedContacts = <Contact>[];

  // ID -> List of specific info type contacts
  final contactsToMerge = <String, List<_MutableContact>>{};

  for (final specificInfoContacts in allContacts) {
    for (final contact in specificInfoContacts) {
      if (contactsToMerge[contact.id] == null) {
        contactsToMerge[contact.id] = [];
      }
      contactsToMerge[contact.id]!.add(contact);
    }
  }

  for (final specificInfoContacts in contactsToMerge.values) {
    mergedContacts.add(
      _getContactByMergingContactInfoTypes(specificInfoContacts),
    );
  }

  return mergedContacts;
}

/// Returns a list [Contact] with info merged from all [contacts].
/// Modifies [contacts] list items in place.
Contact _getContactByMergingContactInfoTypes(List<_MutableContact> contacts) {
  assert(contacts.isNotEmpty);

  final result = contacts[0];

  if (contacts.length == 1) {
    return result;
  }

  for (final c in contacts.skip(1)) {
    if (result.id.isEmpty && c.id.isNotEmpty) {
      result.id = c.id;
    }
    if (result.displayName.isEmpty && c.displayName.isNotEmpty) {
      result.displayName = c.displayName;
    }
    if (result.phones.isEmpty && c.phones.isNotEmpty) {
      result.phones = c.phones;
    }
    if (result.emails.isEmpty && c.emails.isNotEmpty) {
      result.emails = c.emails;
    }
    if (result.structuredName == null && c.structuredName != null) {
      result.structuredName = c.structuredName;
    }
    if (result.organization == null && c.organization != null) {
      result.organization = c.organization;
    }
  }

  return result;
}
