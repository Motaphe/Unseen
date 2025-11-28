import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unseen/models/hunt.dart';
import 'package:unseen/models/clue.dart';
import 'package:unseen/models/user_progress.dart';
import 'package:unseen/utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== HUNT OPERATIONS ==========

  /// Get all available hunts
  Stream<List<Hunt>> getHunts() {
    return _firestore
        .collection(AppConstants.huntsCollection)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final hunts = snapshot.docs.map((doc) => Hunt.fromFirestore(doc)).toList();
          // Sort in memory to avoid requiring a composite index
          hunts.sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return a.createdAt!.compareTo(b.createdAt!);
          });
          return hunts;
        });
  }

  /// Get a single hunt by ID
  Future<Hunt?> getHunt(String huntId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.huntsCollection)
          .doc(huntId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Connection timeout - Firestore unavailable');
            },
          );
      if (doc.exists) {
        return Hunt.fromFirestore(doc);
      }
      return null;
    } on FirebaseException catch (e) {
      // Handle Firebase-specific errors
      throw Exception('Firebase error: ${e.message ?? e.code}');
    } catch (e) {
      // Handle other errors (including Google Play Services errors)
      final errorMessage = e.toString();
      if (errorMessage.contains('GoogleApiManager') ||
          errorMessage.contains('SecurityException') ||
          errorMessage.contains('Phenotype') ||
          errorMessage.contains('DEVELOPER_ERROR')) {
        throw Exception('Google Play Services unavailable. Please ensure Google Play Services is installed and up to date.');
      }
      throw Exception('Failed to get hunt: $e');
    }
  }

  /// Get hunt stream (for real-time updates)
  Stream<Hunt?> getHuntStream(String huntId) {
    return _firestore
        .collection(AppConstants.huntsCollection)
        .doc(huntId)
        .snapshots()
        .map((doc) => doc.exists ? Hunt.fromFirestore(doc) : null);
  }

  // ========== CLUE OPERATIONS ==========

  /// Get all clues for a hunt, ordered by their order field
  Future<List<Clue>> getCluesForHunt(String huntId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.cluesCollection)
          .where('huntId', isEqualTo: huntId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Connection timeout - Firestore unavailable');
            },
          );
      final clues = snapshot.docs.map((doc) => Clue.fromFirestore(doc)).toList();
      // Sort in memory to avoid requiring a composite index
      clues.sort((a, b) => a.order.compareTo(b.order));
      return clues;
    } on FirebaseException catch (e) {
      // Handle Firebase-specific errors
      throw Exception('Firebase error: ${e.message ?? e.code}');
    } catch (e) {
      // Handle other errors (including Google Play Services errors)
      final errorMessage = e.toString();
      if (errorMessage.contains('GoogleApiManager') ||
          errorMessage.contains('SecurityException') ||
          errorMessage.contains('Phenotype') ||
          errorMessage.contains('DEVELOPER_ERROR')) {
        throw Exception('Google Play Services unavailable. Please ensure Google Play Services is installed and up to date.');
      }
      throw Exception('Failed to get clues: $e');
    }
  }

  /// Get clues stream for real-time updates
  Stream<List<Clue>> getCluesForHuntStream(String huntId) {
    return _firestore
        .collection(AppConstants.cluesCollection)
        .where('huntId', isEqualTo: huntId)
        .snapshots()
        .map((snapshot) {
          final clues = snapshot.docs.map((doc) => Clue.fromFirestore(doc)).toList();
          // Sort in memory to avoid requiring a composite index
          clues.sort((a, b) => a.order.compareTo(b.order));
          return clues;
        });
  }

  /// Get a single clue by ID
  Future<Clue?> getClue(String clueId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.cluesCollection)
          .doc(clueId)
          .get();
      if (doc.exists) {
        return Clue.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get clue: $e');
    }
  }

  // ========== USER PROGRESS OPERATIONS ==========

  /// Get or create user progress for a hunt
  Future<UserProgress> getOrCreateProgress({
    required String userId,
    required String huntId,
  }) async {
    try {
      final progressId = '${userId}_$huntId';
      final doc = await _firestore
          .collection(AppConstants.progressCollection)
          .doc(progressId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Connection timeout - Firestore unavailable');
            },
          );

      if (doc.exists) {
        return UserProgress.fromFirestore(doc);
      } else {
        // Create new progress
        final newProgress = UserProgress(
          id: progressId,
          userId: userId,
          huntId: huntId,
          currentClueOrder: 0,
          cluesFound: [],
          evidencePhotos: const {},
        );
        await _firestore
            .collection(AppConstants.progressCollection)
            .doc(progressId)
            .set(newProgress.toFirestore())
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw Exception('Connection timeout - Firestore unavailable');
              },
            );
        return newProgress;
      }
    } on FirebaseException catch (e) {
      // Handle Firebase-specific errors
      throw Exception('Firebase error: ${e.message ?? e.code}');
    } catch (e) {
      // Handle other errors (including Google Play Services errors)
      final errorMessage = e.toString();
      if (errorMessage.contains('GoogleApiManager') ||
          errorMessage.contains('SecurityException') ||
          errorMessage.contains('Phenotype') ||
          errorMessage.contains('DEVELOPER_ERROR')) {
        throw Exception('Google Play Services unavailable. Please ensure Google Play Services is installed and up to date.');
      }
      throw Exception('Failed to get/create progress: $e');
    }
  }

  /// Get user progress stream
  Stream<UserProgress?> getProgressStream({
    required String userId,
    required String huntId,
  }) {
    final progressId = '${userId}_$huntId';
    return _firestore
        .collection(AppConstants.progressCollection)
        .doc(progressId)
        .snapshots()
        .map((doc) => doc.exists ? UserProgress.fromFirestore(doc) : null);
  }

  /// Update user progress when a clue is found
  Future<void> markClueFound({
    required String userId,
    required String huntId,
    required String clueId,
    String? photoUrl,
  }) async {
    try {
      final progressId = '${userId}_$huntId';
      final progressDoc = _firestore
          .collection(AppConstants.progressCollection)
          .doc(progressId);

      final data = <String, dynamic>{
        'cluesFound': FieldValue.arrayUnion([clueId]),
        'currentClueOrder': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (photoUrl != null) {
        data['evidencePhotos.$clueId'] = photoUrl;
      }

      await progressDoc.set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to mark clue as found: $e');
    }
  }

  /// Reset a user's progress for a hunt (used when replaying)
  Future<void> resetProgress({
    required String userId,
    required String huntId,
  }) async {
    try {
      final progressId = '${userId}_$huntId';
      final resetPayload = UserProgress(
        id: progressId,
        userId: userId,
        huntId: huntId,
        currentClueOrder: 0,
        cluesFound: const [],
        evidencePhotos: const {},
        startedAt: DateTime.now(),
      ).toFirestore();

      await _firestore
          .collection(AppConstants.progressCollection)
          .doc(progressId)
          .set(resetPayload);
    } catch (e) {
      throw Exception('Failed to reset progress: $e');
    }
  }

  /// Complete a hunt
  Future<void> completeHunt({
    required String userId,
    required String huntId,
    required int timeTakenSeconds,
    required int pointsEarned,
    bool awardPoints = true,
  }) async {
    try {
      final progressId = '${userId}_$huntId';
      await _firestore
          .collection(AppConstants.progressCollection)
          .doc(progressId)
          .update({
        'completedAt': FieldValue.serverTimestamp(),
        'timeTakenSeconds': timeTakenSeconds,
        'pointsEarned': pointsEarned,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update user document with completed hunt (skip for replays)
      if (awardPoints) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .update({
          'huntsCompleted': FieldValue.arrayUnion([huntId]),
          'totalPoints': FieldValue.increment(pointsEarned),
        });
      }
    } catch (e) {
      throw Exception('Failed to complete hunt: $e');
    }
  }

  /// Get all progress for a user
  Future<List<UserProgress>> getUserProgress(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.progressCollection)
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) => UserProgress.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get user progress: $e');
    }
  }

  /// Get completed hunts for a user
  Future<List<UserProgress>> getCompletedHunts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.progressCollection)
          .where('userId', isEqualTo: userId)
          .get();
      // Filter for completed hunts in memory (Firestore doesn't support isNotNull queries easily)
      final progressList = snapshot.docs
          .map((doc) => UserProgress.fromFirestore(doc))
          .where((progress) => progress.completedAt != null)
          .toList();
      // Sort by completion date (most recent first)
      progressList.sort((a, b) {
        if (a.completedAt == null && b.completedAt == null) return 0;
        if (a.completedAt == null) return 1;
        if (b.completedAt == null) return -1;
        return b.completedAt!.compareTo(a.completedAt!);
      });
      return progressList;
    } catch (e) {
      throw Exception('Failed to get completed hunts: $e');
    }
  }

  /// Get user stats (total points, completed hunts count)
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        return {
          'totalPoints': data['totalPoints'] ?? 0,
          'huntsCompleted': (data['huntsCompleted'] as List?)?.length ?? 0,
          'huntsCompletedIds': List<String>.from(data['huntsCompleted'] ?? []),
        };
      }
      
      // If user document doesn't exist, calculate from progress
      final completedProgress = await getCompletedHunts(userId);
      final totalPoints = completedProgress.fold<int>(
        0,
        (total, progress) => total + (progress.pointsEarned ?? 0),
      );
      
      return {
        'totalPoints': totalPoints,
        'huntsCompleted': completedProgress.length,
        'huntsCompletedIds': completedProgress.map((p) => p.huntId).toList(),
      };
    } catch (e) {
      throw Exception('Failed to get user stats: $e');
    }
  }

  // ========== ADMIN/SEED OPERATIONS ==========

  /// Create a hunt (for seeding/admin)
  Future<void> createHunt(Hunt hunt) async {
    try {
      await _firestore
          .collection(AppConstants.huntsCollection)
          .doc(hunt.id)
          .set(hunt.toFirestore());
    } catch (e) {
      throw Exception('Failed to create hunt: $e');
    }
  }

  /// Create a clue (for seeding/admin)
  Future<void> createClue(Clue clue) async {
    try {
      await _firestore
          .collection(AppConstants.cluesCollection)
          .doc(clue.id)
          .set(clue.toFirestore());
    } catch (e) {
      throw Exception('Failed to create clue: $e');
    }
  }

  /// Seed "The Forgotten Ritual" hunt
  Future<void> seedForgottenRitualHunt() async {
    try {
      // Create hunt
      final hunt = Hunt(
        id: 'forgotten_ritual',
        name: 'The Forgotten Ritual',
        description:
            'A cult performed a ritual here decades ago. Something was summoned. Track the ritual components with QR marks before it finds you.',
        difficulty: 'nightmare',
        clueCount: 5,
        clueIds: ['clue_1', 'clue_2', 'clue_3', 'clue_4', 'clue_5'],
        isAvailable: true,
        estimatedTime: '30 min',
      );
      await createHunt(hunt);

      // Create clues
      final clues = [
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
      ];

      for (final clue in clues) {
        await createClue(clue);
      }
    } catch (e) {
      throw Exception('Failed to seed hunt: $e');
    }
  }

  /// Seed "The Phantom's Lullaby" hunt
  Future<void> seedPhantomsLullabyHunt() async {
    try {
      final hunt = Hunt(
        id: 'phantoms_lullaby',
        name: 'The Phantom\'s Lullaby',
        description:
            'A child\'s music box plays a haunting melody that only you can hear. Follow the notes to uncover the truth behind the phantom that never sleeps.',
        difficulty: 'easy',
        clueCount: 4,
        clueIds: ['phantom_clue_1', 'phantom_clue_2', 'phantom_clue_3', 'phantom_clue_4'],
        isAvailable: true,
        estimatedTime: '20 min',
      );
      await createHunt(hunt);

      final clues = [
        Clue(
          id: 'phantom_clue_1',
          huntId: 'phantoms_lullaby',
          order: 1,
          hint: 'Where melodies begin...',
          fullHint: 'Place this QR near any music player, speaker, or sound system.',
          locationHint: 'Bluetooth speaker, stereo system, or phone dock.',
          narrative:
              'A faint melody drifts through the air. It sounds like a music box, but you see nothing. The tune is familiar, yet you cannot place it.',
          qrCode: 'UNSEEN_PHANTOM_001',
          arModelId: 'music_box',
        ),
        Clue(
          id: 'phantom_clue_2',
          huntId: 'phantoms_lullaby',
          order: 2,
          hint: 'Seek where time stands still...',
          fullHint: 'Hide this QR near a clock, watch, or timepiece.',
          locationHint: 'Wall clock, bedside alarm, or watch display.',
          narrative:
              'The clock\'s hands move backwards. No, that\'s impossible. But the melody grows louder. Something wants you to remember.',
          qrCode: 'UNSEEN_PHANTOM_002',
          arModelId: 'pocket_watch',
        ),
        Clue(
          id: 'phantom_clue_3',
          huntId: 'phantoms_lullaby',
          order: 3,
          hint: 'Find where memories rest...',
          fullHint: 'Place this QR near photos, picture frames, or a memory board.',
          locationHint: 'Photo frame, gallery wall, or memory display.',
          narrative:
              'A child\'s face appears in the photo. You don\'t recognize them, but your heart aches. The music box plays their favorite song.',
          qrCode: 'UNSEEN_PHANTOM_003',
          arModelId: 'photo_frame',
        ),
        Clue(
          id: 'phantom_clue_4',
          huntId: 'phantoms_lullaby',
          order: 4,
          hint: 'Where the lullaby ends...',
          fullHint: 'Place the final QR near a bed, pillow, or sleeping area.',
          locationHint: 'Bedside table, pillow, or headboard.',
          narrative:
              'The melody fades. A small voice whispers "Thank you for remembering." The phantom can finally rest. The music box stops.',
          qrCode: 'UNSEEN_PHANTOM_004',
          arModelId: 'music_box_open',
        ),
      ];

      for (final clue in clues) {
        await createClue(clue);
      }
    } catch (e) {
      throw Exception('Failed to seed hunt: $e');
    }
  }

  /// Seed "The Whispering Walls" hunt
  Future<void> seedWhisperingWallsHunt() async {
    try {
      final hunt = Hunt(
        id: 'whispering_walls',
        name: 'The Whispering Walls',
        description:
            'The walls have ears, and they\'re telling secrets. A ghostly presence has been trapped in this building for decades. Help them find peace by uncovering their story.',
        difficulty: 'medium',
        clueCount: 6,
        clueIds: ['wall_clue_1', 'wall_clue_2', 'wall_clue_3', 'wall_clue_4', 'wall_clue_5', 'wall_clue_6'],
        isAvailable: true,
        estimatedTime: '35 min',
      );
      await createHunt(hunt);

      final clues = [
        Clue(
          id: 'wall_clue_1',
          huntId: 'whispering_walls',
          order: 1,
          hint: 'Where voices echo first...',
          fullHint: 'Place this QR near a door or entryway where voices would first be heard.',
          locationHint: 'Main entrance, doorway, or hall entry point.',
          narrative:
              'A whisper reaches your ears. "Help me..." The voice is faint, desperate. It seems to come from everywhere and nowhere at once.',
          qrCode: 'UNSEEN_WALLS_001',
          arModelId: 'doorway',
        ),
        Clue(
          id: 'wall_clue_2',
          huntId: 'whispering_walls',
          order: 2,
          hint: 'Seek where warmth once lived...',
          fullHint: 'Hide this QR near a fireplace, heater, or warm spot.',
          locationHint: 'Fireplace mantel, radiator, or heating vent.',
          narrative:
              'The whisper grows clearer. "I was happy here... before the fire." Cold air rushes past you, but there is no fire now.',
          qrCode: 'UNSEEN_WALLS_002',
          arModelId: 'fireplace',
        ),
        Clue(
          id: 'wall_clue_3',
          huntId: 'whispering_walls',
          order: 3,
          hint: 'Find where secrets hide...',
          fullHint: 'Place this QR near a drawer, cabinet, or hidden storage.',
          locationHint: 'Desk drawer, kitchen cabinet, or storage box.',
          narrative:
              '"They never found my letter." A drawer creaks open on its own. Inside, you see nothing, but the whisper tells you to look closer.',
          qrCode: 'UNSEEN_WALLS_003',
          arModelId: 'letter',
        ),
        Clue(
          id: 'wall_clue_4',
          huntId: 'whispering_walls',
          order: 4,
          hint: 'Look where stairs ascend...',
          fullHint: 'Place this QR near stairs, a ladder, or elevated area.',
          locationHint: 'Staircase railing, step, or ladder rung.',
          narrative:
              '"I fell... but I didn\'t mean to." The whisper is clearer now, filled with regret. The stairs creak under invisible weight.',
          qrCode: 'UNSEEN_WALLS_004',
          arModelId: 'stairs',
        ),
        Clue(
          id: 'wall_clue_5',
          huntId: 'whispering_walls',
          order: 5,
          hint: 'Seek where light fades...',
          fullHint: 'Place this QR near a window, especially one facing away from light.',
          locationHint: 'Window sill, curtain rod, or darkened window.',
          narrative:
              '"The darkness took me, but I\'m still here." The window reflects something behind you, but when you turn, nothing is there.',
          qrCode: 'UNSEEN_WALLS_005',
          arModelId: 'window',
        ),
        Clue(
          id: 'wall_clue_6',
          huntId: 'whispering_walls',
          order: 6,
          hint: 'Where the story ends...',
          fullHint: 'Place the final QR at the center of the building or main room.',
          locationHint: 'Central room, main hall, or building center.',
          narrative:
              '"Thank you... I can rest now." The whisper fades, but you feel a gentle warmth. The walls are silent. The spirit has found peace.',
          qrCode: 'UNSEEN_WALLS_006',
          arModelId: 'peace_symbol',
        ),
      ];

      for (final clue in clues) {
        await createClue(clue);
      }
    } catch (e) {
      throw Exception('Failed to seed hunt: $e');
    }
  }

  /// Seed "The Cursed Artifact" hunt
  Future<void> seedCursedArtifactHunt() async {
    try {
      final hunt = Hunt(
        id: 'cursed_artifact',
        name: 'The Cursed Artifact',
        description:
            'An ancient artifact has been stolen and hidden. Its curse spreads with each passing hour. Track it down before the curse consumes everything.',
        difficulty: 'hard',
        clueCount: 7,
        clueIds: ['artifact_clue_1', 'artifact_clue_2', 'artifact_clue_3', 'artifact_clue_4', 'artifact_clue_5', 'artifact_clue_6', 'artifact_clue_7'],
        isAvailable: true,
        estimatedTime: '45 min',
      );
      await createHunt(hunt);

      final clues = [
        Clue(
          id: 'artifact_clue_1',
          huntId: 'cursed_artifact',
          order: 1,
          hint: 'Where knowledge is kept...',
          fullHint: 'Place this QR in a library, study, or where books are stored.',
          locationHint: 'Bookshelf, study desk, or library corner.',
          narrative:
              'An ancient text speaks of a cursed object. "He who steals it shall be consumed." The pages feel warm, almost alive.',
          qrCode: 'UNSEEN_ARTIFACT_001',
          arModelId: 'ancient_book',
        ),
        Clue(
          id: 'artifact_clue_2',
          huntId: 'cursed_artifact',
          order: 2,
          hint: 'Seek where metal gleams...',
          fullHint: 'Place this QR near metal objects, tools, or hardware.',
          locationHint: 'Toolbox, metal shelf, or hardware drawer.',
          narrative:
              'The curse spreads through metal. Your keys feel heavier. The tools shift position when you look away.',
          qrCode: 'UNSEEN_ARTIFACT_002',
          arModelId: 'ancient_key',
        ),
        Clue(
          id: 'artifact_clue_3',
          huntId: 'cursed_artifact',
          order: 3,
          hint: 'Find where shadows gather...',
          fullHint: 'Place this QR in a dark corner, closet, or shadowy area.',
          locationHint: 'Closet corner, under furniture, or dark nook.',
          narrative:
              'The shadows move independently. Something watches from the darkness. The artifact\'s power grows stronger.',
          qrCode: 'UNSEEN_ARTIFACT_003',
          arModelId: 'shadow_creature',
        ),
        Clue(
          id: 'artifact_clue_4',
          huntId: 'cursed_artifact',
          order: 4,
          hint: 'Look where plants wither...',
          fullHint: 'Place this QR near plants, flowers, or living things.',
          locationHint: 'Potted plant, garden area, or plant shelf.',
          narrative:
              'The plants droop. Their leaves curl and blacken. The curse drains life from everything it touches.',
          qrCode: 'UNSEEN_ARTIFACT_004',
          arModelId: 'withered_plant',
        ),
        Clue(
          id: 'artifact_clue_5',
          huntId: 'cursed_artifact',
          order: 5,
          hint: 'Seek where the ground meets sky...',
          fullHint: 'Place this QR near a window, balcony, or elevated view.',
          locationHint: 'Window ledge, balcony railing, or high shelf.',
          narrative:
              'The sky darkens unnaturally. The artifact calls to you. You must find it before the curse becomes permanent.',
          qrCode: 'UNSEEN_ARTIFACT_005',
          arModelId: 'dark_sky',
        ),
        Clue(
          id: 'artifact_clue_6',
          huntId: 'cursed_artifact',
          order: 6,
          hint: 'Find where time breaks...',
          fullHint: 'Place this QR near clocks, watches, or timepieces.',
          locationHint: 'Clock face, watch display, or timer.',
          narrative:
              'Time slows. The clock ticks backwards. The artifact is close. You can feel its malevolent presence.',
          qrCode: 'UNSEEN_ARTIFACT_006',
          arModelId: 'broken_clock',
        ),
        Clue(
          id: 'artifact_clue_7',
          huntId: 'cursed_artifact',
          order: 7,
          hint: 'Where the curse ends...',
          fullHint: 'Place the final QR in a sacred or protected space.',
          locationHint: 'Altar, special display, or protected area.',
          narrative:
              'You find the artifact. As you touch it, the curse shatters. Light floods the room. The darkness recedes. You have broken the curse.',
          qrCode: 'UNSEEN_ARTIFACT_007',
          arModelId: 'cursed_artifact',
        ),
      ];

      for (final clue in clues) {
        await createClue(clue);
      }
    } catch (e) {
      throw Exception('Failed to seed hunt: $e');
    }
  }

  /// Seed "The Dollhouse" hunt
  Future<void> seedDollhouseHunt() async {
    try {
      final hunt = Hunt(
        id: 'the_dollhouse',
        name: 'The Dollhouse',
        description:
            'A perfect miniature world sits in the corner. But the dolls inside move when you\'re not looking. Uncover the dark secret of the family that never left.',
        difficulty: 'nightmare',
        clueCount: 6,
        clueIds: ['dollhouse_clue_1', 'dollhouse_clue_2', 'dollhouse_clue_3', 'dollhouse_clue_4', 'dollhouse_clue_5', 'dollhouse_clue_6'],
        isAvailable: true,
        estimatedTime: '40 min',
      );
      await createHunt(hunt);

      final clues = [
        Clue(
          id: 'dollhouse_clue_1',
          huntId: 'the_dollhouse',
          order: 1,
          hint: 'Where the family lives...',
          fullHint: 'Place this QR near a dollhouse, miniature display, or toy collection.',
          locationHint: 'Dollhouse, toy shelf, or miniature display.',
          narrative:
              'The dollhouse sits perfectly still. But you swear the father doll was facing the other way. The windows seem to watch you.',
          qrCode: 'UNSEEN_DOLLHOUSE_001',
          arModelId: 'dollhouse',
        ),
        Clue(
          id: 'dollhouse_clue_2',
          huntId: 'the_dollhouse',
          order: 2,
          hint: 'Seek where meals are served...',
          fullHint: 'Place this QR near a dining table, kitchen, or eating area.',
          locationHint: 'Dining table, kitchen counter, or meal area.',
          narrative:
              'The dining room table is set for four. But there are only three dolls in the house. Who is the fourth place for?',
          qrCode: 'UNSEEN_DOLLHOUSE_002',
          arModelId: 'dining_table',
        ),
        Clue(
          id: 'dollhouse_clue_3',
          huntId: 'the_dollhouse',
          order: 3,
          hint: 'Find where children sleep...',
          fullHint: 'Place this QR near a bed, especially a child\'s bed or small bed.',
          locationHint: 'Bed, especially child-sized or small bed.',
          narrative:
              'The child doll is in bed. But its eyes are open. Staring. The blanket has moved. Something is wrong with this family.',
          qrCode: 'UNSEEN_DOLLHOUSE_003',
          arModelId: 'child_bed',
        ),
        Clue(
          id: 'dollhouse_clue_4',
          huntId: 'the_dollhouse',
          order: 4,
          hint: 'Look where secrets are kept...',
          fullHint: 'Place this QR near a locked drawer, safe, or hidden compartment.',
          locationHint: 'Locked drawer, safe, or secret hiding spot.',
          narrative:
              'A drawer in the dollhouse is locked. But you hear scratching from inside. The mother doll\'s head has turned. She\'s watching you.',
          qrCode: 'UNSEEN_DOLLHOUSE_004',
          arModelId: 'locked_drawer',
        ),
        Clue(
          id: 'dollhouse_clue_5',
          huntId: 'the_dollhouse',
          order: 5,
          hint: 'Seek where the truth hides...',
          fullHint: 'Place this QR near a mirror or reflective surface.',
          locationHint: 'Mirror, reflective surface, or glass display.',
          narrative:
              'In the mirror, you see the dollhouse family. But they\'re not dolls anymore. They\'re real. And they\'re trapped. The father points at you.',
          qrCode: 'UNSEEN_DOLLHOUSE_005',
          arModelId: 'distorted_mirror',
        ),
        Clue(
          id: 'dollhouse_clue_6',
          huntId: 'the_dollhouse',
          order: 6,
          hint: 'Where the nightmare ends...',
          fullHint: 'Place the final QR at the dollhouse itself or where it began.',
          locationHint: 'Back at the dollhouse or starting location.',
          narrative:
              'YOU ARE THE FOURTH. The dollhouse was never a toy. It\'s a prison. The family reaches for you. Their hands are real. Their eyes are real. You are becoming one of them. RUN.',
          qrCode: 'UNSEEN_DOLLHOUSE_006',
          arModelId: 'cursed_doll',
        ),
      ];

      for (final clue in clues) {
        await createClue(clue);
      }
    } catch (e) {
      throw Exception('Failed to seed hunt: $e');
    }
  }

  /// Seed "The Midnight Library" hunt
  Future<void> seedMidnightLibraryHunt() async {
    try {
      final hunt = Hunt(
        id: 'midnight_library',
        name: 'The Midnight Library',
        description:
            'At midnight, the library comes alive. Books write themselves, pages turn without readers, and the librarian who never left still roams the aisles. Find the book that holds the key to freedom.',
        difficulty: 'hard',
        clueCount: 5,
        clueIds: ['library_clue_1', 'library_clue_2', 'library_clue_3', 'library_clue_4', 'library_clue_5'],
        isAvailable: true,
        estimatedTime: '35 min',
      );
      await createHunt(hunt);

      final clues = [
        Clue(
          id: 'library_clue_1',
          huntId: 'midnight_library',
          order: 1,
          hint: 'Where stories begin...',
          fullHint: 'Place this QR in a library, bookshelf, or reading area.',
          locationHint: 'Bookshelf, library corner, or reading nook.',
          narrative:
              'The clock strikes midnight. Books begin to whisper. Pages flutter like wings. The library is awake, and it knows you\'re here.',
          qrCode: 'UNSEEN_LIBRARY_001',
          arModelId: 'whispering_book',
        ),
        Clue(
          id: 'library_clue_2',
          huntId: 'midnight_library',
          order: 2,
          hint: 'Seek where knowledge is catalogued...',
          fullHint: 'Place this QR near a card catalog, index, or organization system.',
          locationHint: 'Card catalog, index drawer, or organization system.',
          narrative:
              'The card catalog drawers open and close on their own. A card floats out. It reads: "The Librarian\'s Last Entry." The date is today.',
          qrCode: 'UNSEEN_LIBRARY_002',
          arModelId: 'card_catalog',
        ),
        Clue(
          id: 'library_clue_3',
          huntId: 'midnight_library',
          order: 3,
          hint: 'Find where silence is kept...',
          fullHint: 'Place this QR in a quiet corner, study area, or silent zone.',
          locationHint: 'Study carrel, quiet corner, or silent reading area.',
          narrative:
              'A figure moves between the shelves. The librarian. But they\'ve been dead for years. They turn to you. "Find the book. Free us all."',
          qrCode: 'UNSEEN_LIBRARY_003',
          arModelId: 'ghost_librarian',
        ),
        Clue(
          id: 'library_clue_4',
          huntId: 'midnight_library',
          order: 4,
          hint: 'Look where forbidden knowledge lies...',
          fullHint: 'Place this QR near restricted books, rare collections, or locked sections.',
          locationHint: 'Rare book section, locked case, or restricted area.',
          narrative:
              'A book glows with an inner light. It\'s writing itself. The words form: "The library is a prison. The books are the bars. Find the key."',
          qrCode: 'UNSEEN_LIBRARY_004',
          arModelId: 'glowing_book',
        ),
        Clue(
          id: 'library_clue_5',
          huntId: 'midnight_library',
          order: 5,
          hint: 'Where the story ends...',
          fullHint: 'Place the final QR at the library exit or main desk.',
          locationHint: 'Library exit, main desk, or checkout counter.',
          narrative:
              'You find the book. As you open it, the library falls silent. The librarian smiles and fades away. The books return to normal. The midnight library is free. You have broken the curse.',
          qrCode: 'UNSEEN_LIBRARY_005',
          arModelId: 'key_book',
        ),
      ];

      for (final clue in clues) {
        await createClue(clue);
      }
    } catch (e) {
      throw Exception('Failed to seed hunt: $e');
    }
  }
}
