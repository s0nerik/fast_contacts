import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fast_contacts/fast_contacts.dart';

void main() {
  const MethodChannel channel = MethodChannel('fast_contacts');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FastContacts.platformVersion, '42');
  });
}
