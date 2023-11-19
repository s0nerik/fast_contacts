import 'dart:async';
import 'dart:convert';
import 'dart:typed_data' as td;

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
  String? _text;

  bool _isLoading = false;

  List<ContactField> _fields = ContactField.values.toList();

  final _ctrl = ScrollController();

  Future<void> loadContacts() async {
    try {
      await Permission.contacts.request();
      _isLoading = true;
      if (mounted) setState(() {});
      final sw = Stopwatch()..start();
      _contacts = await FastContacts.getAllContacts(fields: _fields);
      sw.stop();
      _text =
          'Contacts: ${_contacts.length}\nTook: ${sw.elapsedMilliseconds}ms';
    } on PlatformException catch (e) {
      _text = 'Failed to get contacts:\n${e.details}';
    } finally {
      _isLoading = false;
    }
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scrollbarTheme: ScrollbarThemeData(
          trackVisibility: MaterialStateProperty.all(true),
          thumbVisibility: MaterialStateProperty.all(true),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('fast_contacts'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextButton(
              onPressed: loadContacts,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 24,
                    width: 24,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isLoading
                          ? CircularProgressIndicator()
                          : Icon(Icons.refresh),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Load contacts'),
                ],
              ),
            ),
            ExpansionTile(
              title: Row(
                children: [
                  Text('Fields:'),
                  const SizedBox(width: 8),
                  const Spacer(),
                  TextButton(
                    child: Row(
                      children: [
                        if (_fields.length == ContactField.values.length) ...[
                          Icon(Icons.check),
                          const SizedBox(width: 8),
                        ],
                        Text('All'),
                      ],
                    ),
                    onPressed: () => setState(() {
                      _fields = ContactField.values.toList();
                    }),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    child: Row(
                      children: [
                        if (_fields.length == 0) ...[
                          Icon(Icons.check),
                          const SizedBox(width: 8),
                        ],
                        Text('None'),
                      ],
                    ),
                    onPressed: () => setState(() {
                      _fields.clear();
                    }),
                  ),
                ],
              ),
              children: [
                Wrap(
                  spacing: 4,
                  children: [
                    for (final field in ContactField.values)
                      ChoiceChip(
                        label: Text(field.name),
                        selected: _fields.contains(field),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _fields.add(field);
                          } else {
                            _fields.remove(field);
                          }
                        }),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_text ?? 'Tap to load contacts', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Expanded(
              child: Scrollbar(
                controller: _ctrl,
                interactive: true,
                thickness: 24,
                child: ListView.builder(
                  controller: _ctrl,
                  itemCount: _contacts.length,
                  itemExtent: _ContactItem.height,
                  itemBuilder: (_, index) =>
                      _ContactItem(contact: _contacts[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  const _ContactItem({
    Key? key,
    required this.contact,
  }) : super(key: key);

  static final height = 86.0;

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final phones = contact.phones.map((e) => e.number).join(', ');
    final emails = contact.emails.map((e) => e.address).join(', ');
    final name = contact.structuredName;
    final nameStr = name != null
        ? [
            if (name.namePrefix.isNotEmpty) name.namePrefix,
            if (name.givenName.isNotEmpty) name.givenName,
            if (name.middleName.isNotEmpty) name.middleName,
            if (name.familyName.isNotEmpty) name.familyName,
            if (name.nameSuffix.isNotEmpty) name.nameSuffix,
          ].join(', ')
        : '';
    final organization = contact.organization;
    final organizationStr = organization != null
        ? [
            if (organization.company.isNotEmpty) organization.company,
            if (organization.department.isNotEmpty) organization.department,
            if (organization.jobDescription.isNotEmpty)
              organization.jobDescription,
          ].join(', ')
        : '';

    return SizedBox(
      height: height,
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => _ContactDetailsPage(
              contactId: contact.id,
            ),
          ),
        ),
        leading: _ContactImage(contact: contact),
        title: Text(
          contact.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (phones.isNotEmpty)
              Text(
                phones,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (emails.isNotEmpty)
              Text(
                emails,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (nameStr.isNotEmpty)
              Text(
                nameStr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (organizationStr.isNotEmpty)
              Text(
                organizationStr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactImage extends StatefulWidget {
  const _ContactImage({
    Key? key,
    required this.contact,
  }) : super(key: key);

  final Contact contact;

  @override
  __ContactImageState createState() => __ContactImageState();
}

class __ContactImageState extends State<_ContactImage> {
  late Future<td.Uint8List?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = FastContacts.getContactImage(widget.contact.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<td.Uint8List?>(
      future: _imageFuture,
      builder: (context, snapshot) => Container(
        width: 56,
        height: 56,
        child: snapshot.hasData
            ? Image.memory(snapshot.data!, gaplessPlayback: true)
            : Icon(Icons.account_box_rounded),
      ),
    );
  }
}

class _ContactDetailsPage extends StatefulWidget {
  const _ContactDetailsPage({
    Key? key,
    required this.contactId,
  }) : super(key: key);

  final String contactId;

  @override
  State<_ContactDetailsPage> createState() => _ContactDetailsPageState();
}

class _ContactDetailsPageState extends State<_ContactDetailsPage> {
  late Future<Contact?> _contactFuture;

  Duration? _timeTaken;

  @override
  void initState() {
    super.initState();
    final sw = Stopwatch()..start();
    _contactFuture = FastContacts.getContact(widget.contactId).then((value) {
      _timeTaken = (sw..stop()).elapsed;
      return value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact details: ${widget.contactId}'),
      ),
      body: FutureBuilder<Contact?>(
        future: _contactFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final error = snapshot.error;
          if (error != null) {
            return Center(child: Text('Error: $error'));
          }

          final contact = snapshot.data;
          if (contact == null) {
            return const Center(child: Text('Contact not found'));
          }

          final contactJson =
              JsonEncoder.withIndent('  ').convert(contact.toMap());

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ContactImage(contact: contact),
                  const SizedBox(height: 16),
                  if (_timeTaken != null)
                    Text('Took: ${_timeTaken!.inMilliseconds}ms'),
                  const SizedBox(height: 16),
                  Text(contactJson),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
