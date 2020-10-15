import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class Contact {
  Contact._({
    this.id,
    this.displayName,
    this.phones,
  });

  factory Contact.fromMap(Map map) => Contact._(
        id: map['id'] as String,
        displayName: map['displayName'] as String,
        phones: (map['phones'] as List).cast<String>(),
      );

  final String id;
  final String displayName;
  final List<String> phones;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contact &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          phones == other.phones;

  @override
  int get hashCode => id.hashCode ^ displayName.hashCode ^ phones.hashCode;
}

enum ContactImageSize {
  thumbnail,
  fullSize,
}

class FastContacts {
  static const MethodChannel _channel =
      const MethodChannel('com.github.s0nerik.fast_contacts');

  static Future<List<Contact>> get allContacts async {
    final contacts = await _channel.invokeMethod<List>('getContacts');
    return contacts.map((map) => Contact.fromMap(map)).toList();
  }

  static Future<Uint8List> getContactImage(
    String contactId, {
    ContactImageSize size = ContactImageSize.thumbnail,
  }) =>
      _channel.invokeMethod('getContactImage', {
        'id': contactId,
        'size': size == ContactImageSize.thumbnail ? 'thumbnail' : 'fullSize',
      });
}
