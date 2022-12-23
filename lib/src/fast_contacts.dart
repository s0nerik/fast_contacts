import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'model/contact.dart';
import 'util/map_merging.dart';

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
    mergedContactsMap[id]!.mergeWith(contact);
  }

  final mergedContacts = <Contact>[];
  for (final contactMap in mergedContactsMap.values) {
    final contact = Contact.fromMap(contactMap);
    mergedContacts.add(contact);
  }

  return mergedContacts;
}
