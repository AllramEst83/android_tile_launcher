import 'package:android_tile_launcher/services/agenda_repository.dart';
import 'package:android_tile_launcher/services/contacts_repository.dart';
import 'package:android_tile_launcher/services/device_repository.dart';
import 'package:android_tile_launcher/services/mail_service.dart';
import 'package:android_tile_launcher/services/phone_service.dart';
import 'package:android_tile_launcher/services/sms_service.dart';
import 'package:android_tile_launcher/services/system_control_service.dart';
import 'package:android_tile_launcher/services/text_tv_repository.dart';
import 'package:android_tile_launcher/services/tile_services.dart';
import 'package:android_tile_launcher/services/weather_repository.dart';
import 'package:android_tile_launcher/services/whatsapp_service.dart';

import 'fake_agenda_repository.dart';
import 'fake_contacts.dart';
import 'fake_device_repository.dart';
import 'fake_mail_service.dart';
import 'fake_system_control_service.dart';
import 'fake_text_tv_repository.dart';
import 'fake_weather_repository.dart';

/// A [TileServices] made entirely of fakes; pass any of them to look at or
/// steer it.
TileServices fakeTileServices({
  SystemControlService? systemControl,
  DeviceRepository? device,
  WeatherRepository? weather,
  AgendaRepository? agenda,
  ContactsRepository? contacts,
  PhoneService? phone,
  SmsService? sms,
  WhatsAppService? whatsApp,
  MailService? mail,
  TextTvRepository? textTv,
}) => TileServices(
  systemControl: systemControl ?? FakeSystemControlService(),
  device: device ?? FakeDeviceRepository(),
  weather: weather ?? FakeWeatherRepository(),
  agenda: agenda ?? FakeAgendaRepository(),
  contacts: contacts ?? FakeContactsRepository(),
  phone: phone ?? FakePhoneService(),
  sms: sms ?? FakeSmsService(),
  whatsApp: whatsApp ?? FakeWhatsAppService(),
  mail: mail ?? FakeMailService(),
  textTv: textTv ?? FakeTextTvRepository(),
);
