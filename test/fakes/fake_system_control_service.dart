import 'package:android_tile_launcher/model/sound_mode.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/services/system_control_service.dart';

class FakeSystemControlService implements SystemControlService {
  FakeSystemControlService({
    Map<TileKind, bool> initial = const {},
    SoundMode sound = SoundMode.normal,
  }) : _state = Map.of(initial),
       // ignore: prefer_initializing_formals
       _sound = sound;

  final Map<TileKind, bool> _state;
  SoundMode _sound;

  /// `(kind, on)` pairs passed to [setOn], in call order.
  final List<(TileKind, bool)> setCalls = [];

  /// Modes passed to [setSoundMode], in call order.
  final List<SoundMode> soundCalls = [];

  @override
  Future<SoundMode> soundMode() async => _sound;

  @override
  Future<void> setSoundMode(SoundMode mode) async {
    soundCalls.add(mode);
    _sound = mode;
  }

  @override
  Future<bool> isOn(TileKind kind) async => _state[kind] ?? false;

  @override
  Future<void> setOn(TileKind kind, bool on) async {
    setCalls.add((kind, on));
    _state[kind] = on;
  }
}
