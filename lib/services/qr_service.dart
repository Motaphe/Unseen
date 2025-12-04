import 'package:uuid/uuid.dart';

class QrService {
  static const _uuid = Uuid();

  /// Create a short, shareable QR payload for a clue.
  /// Format: UNSEEN_{HUNTID}_{XX}_{RANDOM}
  static String generateClueCode({
    required String huntId,
    required int order,
  }) {
    final slug = huntId.toUpperCase();
    final ord = order.toString().padLeft(2, '0');
    final rand = _uuid.v4().split('-').first.toUpperCase();
    return 'UNSEEN_${slug}_${ord}_$rand';
  }

  /// Slugify a hunt name into a Firestore-safe id.
  static String generateHuntId(String name) {
    final normalized = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final base = normalized.isEmpty ? 'hunt_${DateTime.now().millisecondsSinceEpoch}' : normalized;
    return base;
  }
}
