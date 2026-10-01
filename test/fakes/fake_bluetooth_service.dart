import 'dart:async';

import 'package:android_tile_launcher/model/bluetooth_status.dart';
import 'package:android_tile_launcher/services/bluetooth_service.dart';

/// Answers [status] with whatever is set; records every call to the rest.
/// [emitChange] stands in for a native pair/connect/adapter-state broadcast.
class FakeBluetoothService implements BluetoothService {
  BluetoothStatus statusResult = const BluetoothOn(<PairedDevice>[]);

  int allowCalls = 0;
  int openPanelCalls = 0;
  int openSettingsCalls = 0;

  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Future<BluetoothStatus> status() async => statusResult;

  @override
  Future<void> allow() async => allowCalls++;

  @override
  Future<void> openPanel() async => openPanelCalls++;

  @override
  Future<void> openSettings() async => openSettingsCalls++;

  @override
  Stream<void> get changes => _changes.stream;

  void emitChange() => _changes.add(null);
}
