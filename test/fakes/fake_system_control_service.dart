import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/services/system_control_service.dart';

class FakeSystemControlService implements SystemControlService {
  FakeSystemControlService({Map<TileKind, bool> initial = const {}})
    : _state = Map.of(initial);

  final Map<TileKind, bool> _state;

  /// `(kind, on)` pairs passed to [setOn], in call order.
  final List<(TileKind, bool)> setCalls = [];

  @override
  Future<bool> isOn(TileKind kind) async => _state[kind] ?? false;

  @override
  Future<void> setOn(TileKind kind, bool on) async {
    setCalls.add((kind, on));
    _state[kind] = on;
  }
}
