import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  bool _isEnabled = true;

  bool get isEnabled => _isEnabled;

  // Enable/disable haptics
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  // Check if device supports vibration
  Future<bool> hasVibrator() async {
    if (!_isEnabled) return false;
    final result = await Vibration.hasVibrator();
    return result;
  }

  // Light impact (for subtle feedback)
  void lightImpact() {
    if (!_isEnabled) return;
    HapticFeedback.lightImpact();
  }

  // Medium impact (for standard interactions)
  void mediumImpact() {
    if (!_isEnabled) return;
    HapticFeedback.mediumImpact();
  }

  // Heavy impact (for important events)
  void heavyImpact() {
    if (!_isEnabled) return;
    HapticFeedback.heavyImpact();
  }

  // Selection click (for UI selections)
  void selectionClick() {
    if (!_isEnabled) return;
    HapticFeedback.selectionClick();
  }

  // Custom vibration pattern (for horror effects)
  Future<void> vibratePattern({
    List<int>? pattern,
    int intensity = 255,
  }) async {
    if (!_isEnabled) return;

    final hasVibrator = await this.hasVibrator();
    if (!hasVibrator) return;

    // Default horror pattern: short bursts
    final defaultPattern = [0, 100, 50, 100, 50, 200];
    final vibPattern = pattern ?? defaultPattern;

    final hasAmplitude = await Vibration.hasAmplitudeControl();
    if (hasAmplitude) {
      await Vibration.vibrate(
        pattern: vibPattern,
        intensities: List.filled(
          vibPattern.length,
          intensity,
        ),
      );
    } else {
      await Vibration.vibrate(pattern: vibPattern);
    }
  }

  // Jump scare vibration pattern
  Future<void> jumpScareVibration() async {
    await vibratePattern(
      pattern: [0, 50, 30, 100, 20, 150],
      intensity: 255,
    );
  }

  // Error feedback vibration pattern
  Future<void> errorVibration() async {
    await vibratePattern(
      pattern: [0, 60, 40, 120, 40, 80],
      intensity: 220,
    );
  }

  // Heartbeat vibration pattern
  Future<void> heartbeatVibration() async {
    await vibratePattern(
      pattern: [0, 100, 100, 100, 100, 200],
      intensity: 200,
    );
  }

  // Clue found vibration pattern
  Future<void> clueFoundVibration() async {
    await vibratePattern(
      pattern: [0, 200, 100, 200, 100, 300],
      intensity: 255,
    );
  }
}
