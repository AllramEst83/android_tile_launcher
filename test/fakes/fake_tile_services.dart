import 'package:android_tile_launcher/services/agenda_repository.dart';
import 'package:android_tile_launcher/services/alarm_service.dart';
import 'package:android_tile_launcher/services/app_repository.dart';
import 'package:android_tile_launcher/services/attachment_download_service.dart';
import 'package:android_tile_launcher/services/camera_service.dart';
import 'package:android_tile_launcher/services/clipboard_service.dart';
import 'package:android_tile_launcher/services/contacts_repository.dart';
import 'package:android_tile_launcher/services/device_repository.dart';
import 'package:android_tile_launcher/services/files_service.dart';
import 'package:android_tile_launcher/services/home_role_service.dart';
import 'package:android_tile_launcher/services/link_service.dart';
import 'package:android_tile_launcher/services/mail_service.dart';
import 'package:android_tile_launcher/services/media_service.dart';
import 'package:android_tile_launcher/services/phone_service.dart';
import 'package:android_tile_launcher/services/rates_repository.dart';
import 'package:android_tile_launcher/services/shade_service.dart';
import 'package:android_tile_launcher/services/sms_service.dart';
import 'package:android_tile_launcher/services/system_control_service.dart';
import 'package:android_tile_launcher/services/text_tv_repository.dart';
import 'package:android_tile_launcher/services/tile_services.dart';
import 'package:android_tile_launcher/services/todo_list.dart';
import 'package:android_tile_launcher/services/wallpaper_service.dart';
import 'package:android_tile_launcher/services/weather_repository.dart';
import 'package:android_tile_launcher/services/whatsapp_service.dart';

import 'fake_agenda_repository.dart';
import 'fake_alarm_service.dart';
import 'fake_attachment_download_service.dart';
import 'fake_camera_service.dart';
import 'fake_clipboard_service.dart';
import 'fake_contacts.dart';
import 'fake_device_repository.dart';
import 'fake_files_service.dart';
import 'fake_home_role_service.dart';
import 'fake_link_service.dart';
import 'fake_mail_service.dart';
import 'fake_media_service.dart';
import 'fake_rates_repository.dart';
import 'fake_shade_service.dart';
import 'fake_system_control_service.dart';
import 'fake_text_tv_repository.dart';
import 'fake_wallpaper_service.dart';
import 'fake_weather_repository.dart';
import 'in_memory_local_store.dart';

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
  RatesRepository? rates,
  AlarmService? alarm,
  HomeRoleService? homeRole,
  ClipboardService? clipboard,
  ShadeService? shade,
  WallpaperService? wallpaper,
  AppIconLoader? icons,
  FilesService? files,
  AttachmentDownloadService? attachmentDownload,
  CameraService? camera,
  LinkService? link,
  MediaService? media,
  TodoList? todos,
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
  rates: rates ?? FakeRatesRepository(),
  alarm: alarm ?? FakeAlarmService(),
  homeRole: homeRole ?? FakeHomeRoleService(),
  clipboard: clipboard ?? FakeClipboardService(),
  shade: shade ?? FakeShadeService(),
  wallpaper: wallpaper ?? FakeWallpaperService(),
  icons: icons ?? (String _) async => null,
  files: files ?? FakeFilesService(),
  attachmentDownload: attachmentDownload ?? FakeAttachmentDownloadService(),
  camera: camera ?? FakeCameraService(),
  link: link ?? FakeLinkService(),
  media: media ?? FakeMediaService(),
  todos: todos ?? TodoList(store: InMemoryLocalStore()),
);
