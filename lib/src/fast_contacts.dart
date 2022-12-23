import 'dart:async';

import 'package:flutter/services.dart';

import 'model/contact.dart';

enum ContactImageSize {
  thumbnail,
  fullSize,
}

class FastContacts {
  static const MethodChannel _channel =
      const MethodChannel('com.github.s0nerik.fast_contacts');

  static Future<List<Contact>> getAllContacts() async {
    final result = await _channel.invokeListMethod<Map>('getAllContacts', {
      'fields': ['phones', 'emails', 'structuredName', 'organization'],
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
