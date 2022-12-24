import 'dart:async';

import 'package:fast_contacts/fast_contacts.dart';
import 'package:flutter/services.dart';

import 'model/contact.dart';

enum ContactImageSize {
  thumbnail,
  fullSize,
}

enum ContactField {
  // Name-related
  displayName,
  namePrefix,
  givenName,
  middleName,
  familyName,
  nameSuffix,

  // Organization-related
  company,
  department,
  jobDescription,

  // Phone-related
  phoneNumbers,
  phoneLabels,

  // Email-related
  emailAddresses,
  emailLabels,
}

class FastContacts {
  static const MethodChannel _channel =
      const MethodChannel('com.github.s0nerik.fast_contacts');

  static Future<List<Contact>> getAllContacts({
    List<ContactField> fields = ContactField.values,
  }) async {
    final result = await _channel.invokeListMethod<Map>('getAllContacts', {
      'fields': fields.map((e) => e.name).toList(),
    });
    return result?.map(Contact.fromMap).toList() ?? const [];
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
