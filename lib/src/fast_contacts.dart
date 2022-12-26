import 'dart:async';

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

  static Completer<List<Contact>>? _getAllContactsCompleter;

  static Future<List<Contact>> getAllContacts({
    List<ContactField> fields = ContactField.values,
    int batchSize = 50,
  }) async {
    if (_getAllContactsCompleter != null) {
      return _getAllContactsCompleter!.future;
    }

    _getAllContactsCompleter = Completer();
    try {
      final contacts = await _loadAllContactsPages(fields, batchSize);
      _getAllContactsCompleter!.complete(contacts);
      return contacts;
    } catch (e) {
      _getAllContactsCompleter!.completeError(e);
      rethrow;
    } finally {
      _getAllContactsCompleter = null;
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
        await Future.delayed(Duration(microseconds: 1));
      }
      return contacts;
    } finally {
      await _channel.invokeMethod('clearFetchedContacts');
    }
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
