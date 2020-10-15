import 'dart:async';
import 'dart:typed_data';

import 'package:fast_contacts/fast_contacts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Contact> _contacts = const [];
  String _text;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      await Permission.contacts.request();
      final sw = Stopwatch()..start();
      final contacts = await FastContacts.allContacts;
      _contacts = contacts;
      _text = 'Contacts: ${contacts.length}\nTook: ${sw.elapsedMilliseconds}ms';
    } on PlatformException catch (e) {
      _text = 'Failed to get contacts:\n${e.details}';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            Text(_text ?? ''),
            Expanded(
              child: ListView.builder(
                itemCount: _contacts.length,
                itemBuilder: (context, index) => ListTile(
                  leading: _ContactImage(contact: _contacts[index]),
                  title: Text(_contacts[index].displayName),
                  subtitle: Text(
                    _contacts[index]
                        .phones
                        .firstWhere((_) => true, orElse: () => ''),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactImage extends StatefulWidget {
  const _ContactImage({
    Key key,
    @required this.contact,
  }) : super(key: key);

  final Contact contact;

  @override
  __ContactImageState createState() => __ContactImageState();
}

class __ContactImageState extends State<_ContactImage> {
  Future<Uint8List> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = FastContacts.getContactImage(widget.contact.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _imageFuture,
      builder: (context, snapshot) => Container(
        width: 56,
        height: 56,
        child: snapshot.hasData
            ? Image.memory(snapshot.data, gaplessPlayback: true)
            : null,
      ),
    );
  }
}
