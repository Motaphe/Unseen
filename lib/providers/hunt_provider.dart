import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unseen/models/hunt.dart';
import 'package:unseen/models/clue.dart';
import 'package:unseen/models/user_progress.dart';
import 'package:unseen/services/firestore_service.dart';
import 'package:unseen/services/local_data_service.dart';

enum HuntStatus {
  initial,
  loading,
  loaded,
  error,
}

class HuntProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocalDataService _localDataService = LocalDataService.instance;
  StreamSubscription<List<Hunt>>? _huntsSubscription;

  // Current hunt state
  HuntStatus _status = HuntStatus.initial;
  List<Hunt> _hunts = [];
  Hunt? _currentHunt;
  List<Clue> _currentClues = [];
  UserProgress? _currentProgress;
  String? _errorMessage;
  bool _usingLocalFallback = false;
  bool _awardPointsThisRun = true;

  // Getters
  HuntStatus get status => _status;
  List<Hunt> get hunts => _hunts;
  Hunt? get currentHunt => _currentHunt;
  List<Clue> get currentClues => _currentClues;
  UserProgress? get currentProgress => _currentProgress;
  String? get errorMessage => _errorMessage;
  bool get isUsingLocalData => _usingLocalFallback;
  bool get willAwardPoints => _awardPointsThisRun;

  bool get isLoading => _status == HuntStatus.loading;
  bool get hasError => _status == HuntStatus.error;
  bool get isHuntLoaded => _currentHunt != null && _currentClues.isNotEmpty;

  // Get current clue based on progress
  Clue? get currentClue {
    if (_currentClues.isEmpty || _currentProgress == null) {
      return null;
    }
    final order = _currentProgress!.currentClueOrder;
    if (order >= 0 && order < _currentClues.length) {
      return _currentClues[order];
    }
    return null;
  }

  // Get progress percentage
  double get progressPercentage {
    if (_currentClues.isEmpty || _currentProgress == null) {
      return 0.0;
    }
    return _currentProgress!.cluesFoundCount / _currentClues.length;
  }

  // Check if hunt is completed
  bool get isHuntCompleted {
    if (_currentClues.isEmpty || _currentProgress == null) {
      return false;
    }
    return _currentProgress!.isCompleted ||
        _currentProgress!.cluesFoundCount >= _currentClues.length;
  }

  HuntProvider() {
    _init();
  }

  void _init() {
    // Listen to auth state changes to reset on logout
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        // User logged out, reset state
        _reset();
      }
    });
  }

  void _reset() {
    _huntsSubscription?.cancel();
    _huntsSubscription = null;
    _hunts = [];
    _currentHunt = null;
    _currentClues = [];
    _currentProgress = null;
    _status = HuntStatus.initial;
    _errorMessage = null;
    _usingLocalFallback = false;
    _awardPointsThisRun = true;
    notifyListeners();
  }

  // Load all available hunts
  Future<void> loadHunts() async {
    try {
      _status = HuntStatus.loading;
      _errorMessage = null;
      _usingLocalFallback = false;
      notifyListeners();

      // Listen to hunts stream
      await _huntsSubscription?.cancel();
      _huntsSubscription = _firestoreService.getHunts().listen((hunts) {
        if (hunts.isEmpty) {
          _useLocalHunts('No hunts returned from Firestore');
          return;
        }
        _hunts = hunts;
        _status = HuntStatus.loaded;
        _usingLocalFallback = false;
        notifyListeners();
      }, onError: (error) {
        _useLocalHunts('Failed to load hunts: $error');
      });
    } catch (e) {
      _useLocalHunts('Failed to load hunts: $e');
    }
  }

  // Load a specific hunt and its clues
  Future<void> loadHunt(String huntId, {String? userId}) async {
    _status = HuntStatus.loading;
    _errorMessage = null;
    _usingLocalFallback = false;
    notifyListeners();

    // First, check if local data exists - if it does, we can use it as a fallback
    final localHunt = _localDataService.getHunt(huntId);
    final localClues = _localDataService.getCluesForHunt(huntId);
    final hasLocalData = localHunt != null && localClues.isNotEmpty;

    debugPrint('🔍 Loading hunt $huntId...');
    debugPrint('📦 Local data available: $hasLocalData');

    // Try Firestore first, but with aggressive error handling
    try {
      // Get hunt with timeout
      final hunt = await _firestoreService.getHunt(huntId).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏱️ Firestore timeout for hunt');
          throw Exception('Connection timeout');
        },
      );

      if (hunt == null) {
        throw Exception('Hunt not found in Firestore');
      }
      _currentHunt = hunt;

      // Get clues with timeout
      final clues = await _firestoreService.getCluesForHunt(huntId).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏱️ Firestore timeout for clues');
          throw Exception('Connection timeout');
        },
      );

      if (clues.isEmpty) {
        throw Exception('No clues returned for hunt $huntId');
      }
      _currentClues = clues;

      // Get or create progress if userId is provided
      // This is non-blocking - if it fails, we use local progress
      if (userId != null) {
        try {
          _currentProgress = await _firestoreService.getOrCreateProgress(
            userId: userId,
            huntId: huntId,
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('⏱️ Firestore timeout for progress');
              throw Exception('Connection timeout');
            },
          );
          debugPrint('✅ Progress loaded from Firestore');
        } catch (e, stackTrace) {
          // If progress creation fails, use local fallback but continue with hunt
          debugPrint('⚠️ Failed to create progress in Firestore, using local: $e');
          debugPrint('Stack trace: $stackTrace');
          try {
            _currentProgress = _localDataService.getOrCreateProgress(
              userId: userId,
              huntId: huntId,
            );
            debugPrint('✅ Progress created locally');
          } catch (localError) {
            debugPrint('❌ Even local progress creation failed: $localError');
            // Create a minimal progress object
            _currentProgress = UserProgress(
              id: '${userId}_$huntId',
              userId: userId,
              huntId: huntId,
              currentClueOrder: 0,
              cluesFound: const [],
              evidencePhotos: const {},
              startedAt: DateTime.now(),
            );
            debugPrint('✅ Created minimal progress object');
          }
        }
      }

      // Only mark as loaded if we have hunt and clues
      if (_currentHunt != null && _currentClues.isNotEmpty) {
        debugPrint('✅ Successfully loaded hunt from Firestore');
        _status = HuntStatus.loaded;
        _errorMessage = null; // Clear any previous errors
        notifyListeners();
        return;
      } else {
        throw Exception('Hunt or clues missing after Firestore load');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to load hunt $huntId from Firestore: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('🔄 Attempting local fallback...');
      
      // Always try local fallback when Firestore fails
      final loadedLocally = _loadHuntFromLocal(huntId, userId: userId, error: e);
      if (!loadedLocally) {
        _status = HuntStatus.error;
        // Provide more helpful error message
        final errorStr = e.toString();
        if (errorStr.contains('Google Play Services') ||
            errorStr.contains('SecurityException') ||
            errorStr.contains('Phenotype') ||
            errorStr.contains('DEVELOPER_ERROR')) {
          _errorMessage = 'Google Play Services unavailable. Please check your device settings.';
        } else if (errorStr.contains('timeout') || errorStr.contains('Connection')) {
          _errorMessage = 'Connection timeout. Please check your internet connection.';
        } else if (errorStr.contains('Hunt not found')) {
          _errorMessage = 'Hunt "$huntId" not found.';
        } else {
          _errorMessage = 'Failed to load hunt: ${e.toString().split('\n').first}';
        }
        debugPrint('❌ Failed to load hunt: $_errorMessage');
        notifyListeners();
      }
    }
  }

  // Start a hunt (initialize progress)
  Future<void> startHunt(String huntId, String userId) async {
    _errorMessage = null;
    _awardPointsThisRun = true;
    try {
      await loadHunt(huntId, userId: userId);
      // If loadHunt succeeded (either from Firestore or local), we're good
      if (_status == HuntStatus.error) {
        // If status is still error after loadHunt, it means local fallback also failed
        throw Exception(_errorMessage ?? 'Failed to load hunt');
      }
    } catch (e) {
      debugPrint('❌ startHunt failed: $e');
      // Only set error if we don't have local data loaded
      if (_status != HuntStatus.loaded) {
        _errorMessage = 'Failed to start hunt: $e';
        _status = HuntStatus.error;
        notifyListeners();
        rethrow; // Re-throw so the UI can handle it
      }
      // If we have loaded data (from local fallback), don't throw
    }
  }

  // Restart a hunt for replay (do not grant new points/achievements)
  Future<void> restartHunt(String huntId, String userId) async {
    _errorMessage = null;
    _awardPointsThisRun = false;
    try {
      if (_usingLocalFallback) {
        _currentProgress = _localDataService.resetProgress(
          userId: userId,
          huntId: huntId,
        );
      } else {
        await _firestoreService.resetProgress(userId: userId, huntId: huntId);
        _currentProgress = await _firestoreService.getOrCreateProgress(
          userId: userId,
          huntId: huntId,
        );
      }
      _status = HuntStatus.loaded;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to restart hunt: $e';
      _status = HuntStatus.error;
      notifyListeners();
      rethrow;
    }
  }

  // Mark a clue as found
  Future<void> markClueFound(String clueId, String userId, {String? photoUrl}) async {
    if (_currentHunt == null) {
      throw Exception('No hunt loaded');
    }

    try {
      _errorMessage = null;

      if (_usingLocalFallback) {
        _currentProgress = _localDataService.markClueFound(
          userId: userId,
          huntId: _currentHunt!.id,
          clueId: clueId,
          photoUrl: photoUrl,
        );
        notifyListeners();
      } else {
        // Update in Firestore
        await _firestoreService.markClueFound(
          userId: userId,
          huntId: _currentHunt!.id,
          clueId: clueId,
          photoUrl: photoUrl,
        );

        // Update local state
        if (_currentProgress != null) {
          var updated = _currentProgress!.addFoundClue(clueId);
          if (photoUrl != null) {
            updated = updated.addEvidencePhoto(clueId, photoUrl);
          }
          _currentProgress = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to mark clue as found: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Complete the hunt
  Future<void> completeHunt({
    required String userId,
    required int timeTakenSeconds,
    bool? awardPoints,
  }) async {
    if (_currentHunt == null) {
      throw Exception('No hunt loaded');
    }

    try {
      _errorMessage = null;
      final shouldAwardPoints = awardPoints ?? _awardPointsThisRun;

      // Calculate points (100 per clue + time bonus)
      final basePoints = _currentClues.length * 100;
      final timeBonus = timeTakenSeconds < 300 ? 100 : 0; // Bonus if under 5 min
      final totalPoints = basePoints + timeBonus;

      if (_usingLocalFallback) {
        _currentProgress = _localDataService.completeHunt(
          userId: userId,
          huntId: _currentHunt!.id,
          timeTakenSeconds: timeTakenSeconds,
          pointsEarned: totalPoints,
          awardPoints: shouldAwardPoints,
        );
        notifyListeners();
      } else {
        // Update in Firestore
        await _firestoreService.completeHunt(
          userId: userId,
          huntId: _currentHunt!.id,
          timeTakenSeconds: timeTakenSeconds,
          pointsEarned: totalPoints,
          awardPoints: shouldAwardPoints,
        );

        // Update local state
        if (_currentProgress != null) {
          _currentProgress = _currentProgress!.copyWith(
            completedAt: DateTime.now(),
            timeTakenSeconds: timeTakenSeconds,
            pointsEarned: totalPoints,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to complete hunt: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    if (_status == HuntStatus.error) {
      _status = HuntStatus.initial;
    }
    notifyListeners();
  }

  // Clear current hunt (when leaving hunt screen)
  void clearCurrentHunt() {
    _currentHunt = null;
    _currentClues = [];
    _currentProgress = null;
    _awardPointsThisRun = true;
    notifyListeners();
  }

  // User stats
  Map<String, dynamic>? _userStats;
  List<UserProgress> _completedHunts = [];
  bool _isLoadingStats = false;

  Map<String, dynamic>? get userStats => _userStats;
  List<UserProgress> get completedHunts => _completedHunts;
  bool get isLoadingStats => _isLoadingStats;

  // Load user stats and completed hunts
  Future<void> loadUserStats(String userId) async {
    try {
      _isLoadingStats = true;
      notifyListeners();

      final stats = _usingLocalFallback
          ? _localDataService.getUserStats(userId)
          : await _firestoreService.getUserStats(userId);
      final completed = _usingLocalFallback
          ? _localDataService.getCompletedHunts(userId)
          : await _firestoreService.getCompletedHunts(userId);

      _userStats = stats;
      _completedHunts = completed;
      _isLoadingStats = false;
      notifyListeners();
    } catch (e) {
      _isLoadingStats = false;
      _errorMessage = 'Failed to load user stats: $e';
      notifyListeners();
    }
  }

  bool _loadHuntFromLocal(String huntId, {String? userId, Object? error}) {
    debugPrint('🔍 Checking local data for hunt: $huntId');
    final hunt = _localDataService.getHunt(huntId);
    final clues = _localDataService.getCluesForHunt(huntId);

    if (hunt == null || clues.isEmpty) {
      debugPrint('⚠️ No local data for hunt $huntId. Available hunts: ${_localDataService.getHunts().map((h) => h.id).join(", ")}');
      debugPrint('⚠️ Original error: $error');
      return false;
    }

    debugPrint('✅ Found local data for hunt $huntId. Falling back to local mode.');
    debugPrint('⚠️ Original Firestore error: $error');
    _usingLocalFallback = true;
    _currentHunt = hunt;
    _currentClues = clues;

    if (userId != null) {
      _currentProgress = _localDataService.getOrCreateProgress(
        userId: userId,
        huntId: huntId,
      );
    }

    _status = HuntStatus.loaded;
    _errorMessage = null; // Clear error since we successfully loaded from local
    notifyListeners();
    return true;
  }

  void _useLocalHunts(String reason) {
    debugPrint('⚠️ Falling back to local hunts: $reason');
    _usingLocalFallback = true;
    _hunts = _localDataService.getHunts();
    _status = HuntStatus.loaded;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _huntsSubscription?.cancel();
    super.dispose();
  }
}
