import 'dart:async';
import 'dart:typed_data' as td;

import 'package:fast_contacts/fast_contacts.dart';
import 'package:flutter/foundation.dart';
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

  static var _getAllContactsInProgress = false;

  /// Returns all contacts.
  ///
  /// [fields] is a list of fields to fetch. Less fields means faster loading.
  /// By default, all fields are fetched.
  ///
  /// [batchSize] specifies how many contacts are loaded in a single batch under
  /// the hood. Higher values mean faster loading but increase the chances
  /// of UI freezes.
  static Future<List<Contact>> getAllContacts({
    List<ContactField> fields = ContactField.values,
    int batchSize = 50,
  }) async {
    if (_getAllContactsInProgress) {
      throw StateError('getAllContacts is already in progress.');
    }
    _getAllContactsInProgress = true;
    try {
      final contacts = await _loadAllContactsPages(fields, batchSize);
      return contacts;
    } finally {
      _getAllContactsInProgress = false;
    }
  }

  static Future<List<Contact>> _loadAllContactsPages(
    List<ContactField> fields,
    int batchSize,
  ) async {
    final contacts = <Contact>[];
    try {
      final fetchResponse = await _channel.invokeMethod('fetchAllContacts', {
        'fields': fields.map((e) => e.name).toList(),
      });
      final contactsCount = fetchResponse['count'];
      final timeMillis = fetchResponse['timeMillis'];
      debugPrint('Fetched $contactsCount contacts in $timeMillis ms');

      final getStart = DateTime.now().millisecondsSinceEpoch;
      for (int i = 0; i < contactsCount; i += batchSize) {
        final result =
            await _channel.invokeListMethod<Map>('getAllContactsPage', {
          'from': i,
          'to': (i + batchSize).clamp(0, contactsCount),
        });
        final contactsPage = result?.map(Contact.fromMap).toList();
        if (contactsPage != null) {
          contacts.addAll(contactsPage);
        }
      }
      final getEnd = DateTime.now().millisecondsSinceEpoch;
      debugPrint('Received all contacts in ${getEnd - getStart} ms');

      return contacts;
    } finally {
      await _channel.invokeMethod('clearFetchedContacts');
    }
  }

  /// Returns an image of the contact with the given [contactId].
  ///
  /// [size] specifies the size of the image. By default, a thumbnail is returned.
  static Future<td.Uint8List?> getContactImage(
    String contactId, {
    ContactImageSize size = ContactImageSize.thumbnail,
  }) =>
      _channel.invokeMethod('getContactImage', {
        'id': contactId,
        'size': size == ContactImageSize.thumbnail ? 'thumbnail' : 'fullSize',
      });

  /// Returns data of a contact with the given [contactId].
  ///
  /// [fields] is a list of fields to fetch. Less fields means faster loading.
  /// By default, all fields are fetched.
  static Future<Contact?> getContact(
    String contactId, {
    List<ContactField> fields = ContactField.values,
  }) async {
    final result = await _channel.invokeMethod('getContact', {
      'id': contactId,
      'fields': fields.map((e) => e.name).toList(),
    });
    if (result == null) return null;
    return Contact.fromMap(result);
  }
}
