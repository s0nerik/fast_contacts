import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

abstract class Contact {
  String get id;
  String get displayName;
  List<Phone> get phones;
  List<Email> get emails;
  StructuredName? get structuredName;
  Organization? get organization;
}

class Phone {
  Phone._({
    required this.number,
    required this.label,
  });

  factory Phone.fromMap(Map map) {
    return Phone._(
      number: map['number'],
      label: map['label'],
    );
  }

  final String number;
  final String label;
}

class Email {
  Email._({
    required this.address,
    required this.label,
  });

  factory Email.fromMap(Map map) {
    return Email._(
      address: map['address'],
      label: map['label'],
    );
  }

  final String address;
  final String label;
}

class StructuredName {
  StructuredName._({
    required this.namePrefix,
    required this.givenName,
    required this.middleName,
    required this.familyName,
    required this.nameSuffix,
  });

  factory StructuredName.fromMap(Map map) {
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

  factory Organization.fromMap(Map map) {
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

  factory _MutableContact.fromMap(
    Map map, {
    List<ContactField> fields = ContactField.values,
  }) =>
      _MutableContact(
        id: map['id'] as String,
        displayName: fields.contains(ContactField.displayName)
            ? map['displayName'] as String
            : '',
        phones: fields.contains(ContactField.phones)
            ? (map['phones'] as List).map((map) => Phone.fromMap(map)).toList()
            : [],
        emails: fields.contains(ContactField.emails)
            ? (map['emails'] as List).map((map) => Email.fromMap(map)).toList()
            : [],
        structuredName: map['structuredName'] != null &&
                fields.contains(ContactField.structuredName)
            ? StructuredName.fromMap(map['structuredName']!)
            : null,
        organization: map['organization'] != null &&
                fields.contains(ContactField.organization)
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

enum ContactField {
  id,
  displayName,
  phones,
  emails,
  structuredName,
  organization,
}

extension _ContactFieldExt on ContactField {
  String get type {
    switch (this) {
      case ContactField.id:
        return 'id';
      case ContactField.displayName:
        return 'displayName';
      case ContactField.phones:
        return 'phones';
      case ContactField.emails:
        return 'emails';
      case ContactField.structuredName:
        return 'structuredName';
      case ContactField.organization:
        return 'organization';
    }
  }

  bool get hasAndroidSupport {
    switch (this) {
      case ContactField.phones:
      case ContactField.emails:
      case ContactField.structuredName:
      case ContactField.organization:
        return true;
      default:
        return false;
    }
  }
}

extension _ContactFieldListExt on List<ContactField> {
  List<ContactField> get androidSupportedTypes =>
      where((f) => f.hasAndroidSupport).toList();
}

class FastContacts {
  static const MethodChannel _channel =
      const MethodChannel('com.github.s0nerik.fast_contacts');

  static Future<List<Contact>> getAllContacts({
    List<ContactField> fields = ContactField.values,
  }) async {
    if (Platform.isAndroid) {
      return _allContactsAndroid(fields);
    }
    final contacts = await _channel.invokeMethod<List>('getContacts');
    return contacts
            ?.map((map) => _MutableContact.fromMap(map, fields: fields))
            .toList() ??
        const [];
  }

  static Future<List<Contact>> _allContactsAndroid(
      List<ContactField> fields) async {
    final specificInfoContacts = await Future.wait(fields.androidSupportedTypes
        .map(
          (e) => _channel.invokeMethod<List>('getContacts', {
            'type': e.type,
          }).then(_parseMutableContacts),
        )
        .toList());

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
