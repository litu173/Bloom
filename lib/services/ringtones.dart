import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum RingtoneGroup { system, device }

class Ringtone {
  final String id;
  final String name;
  final RingtoneGroup group;
  const Ringtone(this.id, this.name, this.group);
}

/// NOTE: ship real audio files at assets/sounds/<id>.mp3 and register them in
/// pubspec.yaml (see PRODUCT_SPEC.md → Audio Assets). Until then, previews
/// fall back to a system click so the picker is still usable in dev builds.
const List<Ringtone> kRingtones = [
  Ringtone('bloom', 'Bloom (default)', RingtoneGroup.system),
  Ringtone('radar', 'Radar', RingtoneGroup.system),
  Ringtone('chimes', 'Chimes', RingtoneGroup.system),
  Ringtone('reflection', 'Reflection', RingtoneGroup.system),
  Ringtone('beacon', 'Beacon', RingtoneGroup.system),
  Ringtone('birds', 'Morning Birds', RingtoneGroup.device),
  Ringtone('zen', 'Zen Bell', RingtoneGroup.device),
  Ringtone('piano', 'Soft Piano', RingtoneGroup.device),
];

Ringtone getRingtone(String? id) =>
    kRingtones.firstWhere((r) => r.id == id, orElse: () => kRingtones.first);

/// Plays ringtone previews and the looping alarm melody.
class RingtoneService {
  final AudioPlayer _player = AudioPlayer();
  bool _assetsAvailable = true; // flips false after a missing-asset failure

  Future<void> preview(String id) async {
    if (!_assetsAvailable) {
      SystemSound.play(SystemSoundType.click);
      return;
    }
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/$id.mp3'));
    } catch (_) {
      _assetsAvailable = false;
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> stopPreview() => _player.stop();

  /// Starts the looping alarm tone. With [gradual] on, volume eases in over
  /// ~20s like the web app's gradual-volume behavior.
  Future<void> startAlarm(String id, {bool gradual = true}) async {
    if (!_assetsAvailable) return;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(gradual ? 0.45 : 1.0);
      await _player.play(AssetSource('sounds/$id.mp3'));
      if (gradual) {
        const steps = 20;
        for (var i = 1; i <= steps; i++) {
          await Future.delayed(const Duration(seconds: 1));
          if (!_assetsAvailable) return;
          await _player.setVolume(0.45 + (0.55 * i / steps));
        }
      }
    } catch (_) {
      _assetsAvailable = false;
    }
  }

  Future<void> stopAlarm() => _player.stop();

  void dispose() => _player.dispose();
}
