import 'package:android_tile_launcher/model/contact.dart';
import 'package:android_tile_launcher/services/contacts_repository.dart';
import 'package:android_tile_launcher/services/contacts_service.dart';
import 'package:android_tile_launcher/services/phone_service.dart';
import 'package:android_tile_launcher/services/sms_service.dart';
import 'package:android_tile_launcher/services/whatsapp_service.dart';

/// Answers every read with [result].
class FakeContactsService implements ContactsService {
  FakeContactsService([this.result = const ContactsNoAccess()]);

  ContactsResult result;
  int calls = 0;

  @override
  Future<ContactsResult> all() async {
    calls++;
    return result;
  }
}

/// A phone book of [contacts] (or whatever [result] is set to).
class FakeContactsRepository implements ContactsRepository {
  FakeContactsRepository([List<Contact> contacts = const <Contact>[]])
    : result = ContactsRead(contacts);

  ContactsResult result;
  int calls = 0;
  int peeks = 0;

  @override
  Future<ContactsResult> all() async {
    calls++;
    return result;
  }

  @override
  Future<ContactsResult> peek() async {
    peeks++;
    return result;
  }
}

/// Records every number it is asked to call.
class FakePhoneService implements PhoneService {
  CallResult result = const CallPlaced();
  final List<String> called = <String>[];

  @override
  Future<CallResult> call(String number) async {
    called.add(number);
    return result;
  }
}

/// Records every text it is asked to send.
class FakeSmsService implements SmsService {
  SmsResult result = const SmsSent();
  final List<(String, String)> sent = <(String, String)>[];

  @override
  Future<SmsResult> send(String number, String text) async {
    sent.add((number, text));
    return result;
  }
}

/// Records every chat it is asked to open.
class FakeWhatsAppService implements WhatsAppService {
  WhatsAppResult result = const WhatsAppOpened();
  final List<String> opened = <String>[];

  @override
  Future<WhatsAppResult> openChat(String number) async {
    opened.add(number);
    return result;
  }
}
