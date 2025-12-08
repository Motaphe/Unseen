import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AudioService with WidgetsBindingObserver {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal() {
    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }

  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _loopSfxPlayer = AudioPlayer(); // For looping sound effects
  final String _ambientAssetPath = 'audio/background.mp3';
  double _ambientVolume = 0.5;
  bool _ambientLoop = true;
  bool _isEnabled = true;
  bool _isAmbientPlaying = false;
  bool _wasAmbientPlayingBeforePause = false;
  bool _wasLoopSfxPlayingBeforePause = false;

  bool get isEnabled => _isEnabled;
  bool get isAmbientPlaying => _isAmbientPlaying;

  // Enable/disable audio
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      stopAmbient();
      _sfxPlayer.stop();
      stopLoopingSfx();
    }
  }

  // Play ambient background sound (13:42)
  Future<void> playAmbient({bool loop = true, double volume = 0.5}) async {
    if (!_isEnabled) return;
    _ambientLoop = loop;
    _ambientVolume = volume;

    try {
      if (_isAmbientPlaying) {
        return; // Already playing
      }

      // Set loop mode and volume
      await _ambientPlayer.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.release,
      );
      await _ambientPlayer.setVolume(_ambientVolume);
      
      // Play background music (13:42 long, will loop)
      try {
        await _ambientPlayer.play(AssetSource(_ambientAssetPath));
        _isAmbientPlaying = true;
        if (kDebugMode) {
          print('🎵 Playing background music (looping: $loop, volume: $volume)');
        }
      } catch (e) {
        // Audio file not found - fail silently
        if (kDebugMode) {
          print('Audio file not found: background.mp3 - $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing ambient audio: $e');
      }
    }
  }

  // Set ambient volume
  Future<void> setAmbientVolume(double volume) async {
    if (volume < 0.0) volume = 0.0;
    if (volume > 1.0) volume = 1.0;
    _ambientVolume = volume;
    await _ambientPlayer.setVolume(_ambientVolume);
  }

  // Stop ambient sound
  Future<void> stopAmbient() async {
    try {
      await _ambientPlayer.stop();
      _isAmbientPlaying = false;
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping ambient audio: $e');
      }
    }
  }

  // Play sound effect (one-shot)
  Future<void> playSfx(String assetPath, {double volume = 0.7}) async {
    if (!_isEnabled) return;

    try {
      await _sfxPlayer.setVolume(volume);
      await _sfxPlayer.play(AssetSource(assetPath));
    } catch (e) {
      // Audio file not found - fail silently
      if (kDebugMode) {
        print('Audio file not found: $assetPath');
      }
    }
  }

  // Play looping sound effect
  Future<void> playLoopingSfx(String assetPath, {double volume = 0.7}) async {
    if (!_isEnabled) return;

    try {
      await _loopSfxPlayer.setReleaseMode(ReleaseMode.loop);
      await _loopSfxPlayer.setVolume(volume);
      await _loopSfxPlayer.play(AssetSource(assetPath));
    } catch (e) {
      if (kDebugMode) {
        print('Audio file not found: $assetPath');
      }
    }
  }

  // Stop looping sound effect
  Future<void> stopLoopingSfx() async {
    try {
      await _loopSfxPlayer.stop();
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping looping SFX: $e');
      }
    }
  }

  // Play clue found sound
  Future<void> playClueFound() async {
    await playSfx('audio/clue_found.mp3', volume: 0.8);
  }

  // Play jump scare sound
  Future<void> playJumpScare() async {
    await playSfx('audio/jump_scare.mp3', volume: 1.0);
  }

  // Play heartbeat sound (looping - 11s)
  Future<void> playHeartbeat({bool loop = true}) async {
    if (loop) {
      await playLoopingSfx('audio/heartbeat.mp3', volume: 0.6);
    } else {
      await playSfx('audio/heartbeat.mp3', volume: 0.6);
    }
  }

  // Stop heartbeat
  Future<void> stopHeartbeat() async {
    await stopLoopingSfx();
  }

  // Play footsteps sound (looping - 4.5s)
  Future<void> playFootsteps({bool loop = true}) async {
    if (loop) {
      await playLoopingSfx('audio/footsteps.mp3', volume: 0.5);
    } else {
      await playSfx('audio/footsteps.mp3', volume: 0.5);
    }
  }

  // Stop footsteps
  Future<void> stopFootsteps() async {
    await stopLoopingSfx();
  }

  // Play whispers sound (looping - 11.1s)
  Future<void> playWhispers({bool loop = true}) async {
    if (loop) {
      await playLoopingSfx('audio/whispers.mp3', volume: 0.4);
    } else {
      await playSfx('audio/whispers.mp3', volume: 0.4);
    }
  }

  // Play a quick whisper sting (non-looping) for error/creepy cues
  Future<void> playDistantWhisper() async {
    await playSfx('audio/whispers.mp3', volume: 0.35);
  }

  // Stop whispers
  Future<void> stopWhispers() async {
    await stopLoopingSfx();
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App is going to background or being minimized
        _handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        // App is coming back to foreground
        _handleAppResumed();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is being terminated or hidden
        _handleAppPaused();
        break;
    }
  }

  // Pause all audio when app is backgrounded
  Future<void> _handleAppPaused() async {
    if (kDebugMode) {
      print('🎵 App paused - stopping audio');
    }

    // Save state of what was playing
    final ambientState = _ambientPlayer.state;
    final loopSfxState = _loopSfxPlayer.state;
    final sfxState = _sfxPlayer.state;
    _wasAmbientPlayingBeforePause = ambientState == PlayerState.playing;
    _wasLoopSfxPlayingBeforePause = loopSfxState == PlayerState.playing;

    // Pause all audio
    if (_wasAmbientPlayingBeforePause) {
      await _ambientPlayer.pause();
    }
    if (_wasLoopSfxPlayingBeforePause) {
      await _loopSfxPlayer.pause();
    }
    if (sfxState == PlayerState.playing) {
      await _sfxPlayer.pause();
    }
  }

  // Resume audio when app comes back to foreground
  Future<void> _handleAppResumed() async {
    if (!_isEnabled) return;

    if (kDebugMode) {
      print('🎵 App resumed - resuming audio (ambient: $_wasAmbientPlayingBeforePause, loopSfx: $_wasLoopSfxPlayingBeforePause)');
    }

    // Resume ambient if it was playing before
    if (_wasAmbientPlayingBeforePause) {
      final ambientState = _ambientPlayer.state;
      try {
        if (ambientState == PlayerState.paused) {
          await _ambientPlayer.resume();
        } else if (ambientState != PlayerState.playing) {
          await playAmbient(loop: _ambientLoop, volume: _ambientVolume);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error resuming ambient audio, retrying with play(): $e');
        }
        await playAmbient(loop: _ambientLoop, volume: _ambientVolume);
      }
    }

    // Resume looping SFX if it was playing before
    if (_wasLoopSfxPlayingBeforePause) {
      final loopSfxState = _loopSfxPlayer.state;
      if (loopSfxState == PlayerState.paused) {
        await _loopSfxPlayer.resume();
      }
    }
  }

  // Dispose resources
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ambientPlayer.dispose();
    _sfxPlayer.dispose();
    _loopSfxPlayer.dispose();
  }
}
