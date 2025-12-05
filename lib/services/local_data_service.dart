import 'package:unseen/models/clue.dart';
import 'package:unseen/models/hunt.dart';
import 'package:unseen/models/user_progress.dart';

/// Simple in-memory fallback data source so the app can run without Firestore
/// (e.g. on devices with no internet/DNS access).
class LocalDataService {
  LocalDataService._();

  static final LocalDataService instance = LocalDataService._();

  final Map<String, Hunt> _hunts = {
    'forgotten_ritual': Hunt(
      id: 'forgotten_ritual',
      name: 'The Forgotten Ritual',
      description:
          'A cult performed a ritual here decades ago. Something was summoned. Track the ritual components with QR marks before it finds you.',
      difficulty: 'nightmare',
      clueCount: 5,
      clueIds: const ['clue_1', 'clue_2', 'clue_3', 'clue_4', 'clue_5'],
      isAvailable: true,
      estimatedTime: '30 min',
    ),
  };

  final Map<String, List<Clue>> _cluesByHunt = {
    'forgotten_ritual': [
      Clue(
        id: 'clue_1',
        huntId: 'forgotten_ritual',
        order: 1,
        hint: 'Begin where stories sleep...',
        fullHint: 'Hide the first QR on a bookshelf or stack of forgotten books.',
        locationHint: 'Bookshelf or stack of books. Slide the code under a spine.',
        narrative:
            'The dust stirs. A page turns on its own. Something knows you are searching.',
        qrCode: 'UNSEEN_RITUAL_001',
        arModelId: 'old_book',
      ),
      Clue(
        id: 'clue_2',
        huntId: 'forgotten_ritual',
        order: 2,
        hint: 'Seek where you quench your thirst...',
        fullHint: 'Place this QR near a sink, water fountain, or fridge door.',
        locationHint: 'Kitchen sink, water cooler, or fridge handle.',
        narrative:
            'The water runs cold. Too cold. Metallic aftertaste clings to your tongue.',
        qrCode: 'UNSEEN_RITUAL_002',
        arModelId: 'chalice',
      ),
      Clue(
        id: 'clue_3',
        huntId: 'forgotten_ritual',
        order: 3,
        hint: 'Find where light dances with shadow...',
        fullHint: 'Stick this QR near a lamp, window shade, or light switch.',
        locationHint: 'Lamp base, window frame, or beside a light switch.',
        narrative:
            'The light flickers. It is not the bulb. The shadow on the wall does not match your shape.',
        qrCode: 'UNSEEN_RITUAL_003',
        arModelId: 'candles',
      ),
      Clue(
        id: 'clue_4',
        huntId: 'forgotten_ritual',
        order: 4,
        hint: 'Look where reflections lie...',
        fullHint: 'Tape this QR beside a mirror or shiny surface.',
        locationHint: 'Bathroom mirror corner or wardrobe mirror frame.',
        narrative:
            'Your reflection blinks. You did not. A shape stands beside you, but you are alone.',
        qrCode: 'UNSEEN_RITUAL_004',
        arModelId: 'doll',
      ),
      Clue(
        id: 'clue_5',
        huntId: 'forgotten_ritual',
        order: 5,
        hint: 'Return to where you began. Face what follows.',
        fullHint: 'Place the final QR near the entrance or the starting spot.',
        locationHint: 'Front door frame or the table where you brief players.',
        narrative:
            'YOU SHOULDN\'T HAVE LOOKED. The air freezes. Footsteps behind you. Do not turn around.',
        qrCode: 'UNSEEN_RITUAL_005',
        arModelId: 'ritual_circle',
      ),
    ],
  };

  final Map<String, UserProgress> _progressStore = {};

  List<Hunt> getHunts() {
    final hunts = _hunts.values.where((hunt) => hunt.isAvailable).toList();
    hunts.sort((a, b) => a.name.compareTo(b.name));
    return hunts;
  }

  Hunt? getHunt(String huntId) => _hunts[huntId];

  List<Clue> getCluesForHunt(String huntId) {
    final clues = List<Clue>.from(_cluesByHunt[huntId] ?? const []);
    clues.sort((a, b) => a.order.compareTo(b.order));
    return clues;
  }

  UserProgress getOrCreateProgress({
    required String userId,
    required String huntId,
  }) {
    final progressId = '${userId}_$huntId';
    final existing = _progressStore[progressId];
    if (existing != null) return existing;

    final progress = UserProgress(
      id: progressId,
      userId: userId,
      huntId: huntId,
      currentClueOrder: 0,
      cluesFound: const [],
      evidencePhotos: const {},
      startedAt: DateTime.now(),
    );
    _progressStore[progressId] = progress;
    return progress;
  }

  UserProgress markClueFound({
    required String userId,
    required String huntId,
    required String clueId,
    String? photoUrl,
  }) {
    final progress = getOrCreateProgress(userId: userId, huntId: huntId);
    var updated = progress.addFoundClue(clueId);
    if (photoUrl != null) {
      updated = updated.addEvidencePhoto(clueId, photoUrl);
    }
    updated = updated.copyWith(updatedAt: DateTime.now());
    _progressStore[progress.id] = updated;
    return updated;
  }

  UserProgress completeHunt({
    required String userId,
    required String huntId,
    required int timeTakenSeconds,
    required int pointsEarned,
    bool awardPoints = true,
  }) {
    final progress = getOrCreateProgress(userId: userId, huntId: huntId);
    final effectivePoints = awardPoints ? pointsEarned : (progress.pointsEarned ?? 0);
    final completed = progress.copyWith(
      completedAt: DateTime.now(),
      timeTakenSeconds: timeTakenSeconds,
      pointsEarned: effectivePoints,
      updatedAt: DateTime.now(),
    );
    _progressStore[progress.id] = completed;
    return completed;
  }

  UserProgress resetProgress({
    required String userId,
    required String huntId,
  }) {
    final progressId = '${userId}_$huntId';
    final reset = UserProgress(
      id: progressId,
      userId: userId,
      huntId: huntId,
      currentClueOrder: 0,
      cluesFound: const [],
      evidencePhotos: const {},
      startedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _progressStore[progressId] = reset;
    return reset;
  }

  Map<String, dynamic> getUserStats(String userId) {
    final completed = getCompletedHunts(userId);
    final totalPoints = completed.fold<int>(
      0,
      (sum, progress) => sum + (progress.pointsEarned ?? 0),
    );

    return {
      'totalPoints': totalPoints,
      'huntsCompleted': completed.length,
      'huntsCompletedIds': completed.map((p) => p.huntId).toList(),
    };
  }

  List<UserProgress> getCompletedHunts(String userId) {
    final completed = _progressStore.values
        .where((progress) =>
            progress.userId == userId && progress.completedAt != null)
        .toList();
    completed.sort((a, b) {
      if (a.completedAt == null || b.completedAt == null) return 0;
      return b.completedAt!.compareTo(a.completedAt!);
    });
    return completed;
  }
}
