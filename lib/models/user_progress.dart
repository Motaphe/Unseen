import 'package:cloud_firestore/cloud_firestore.dart';

class UserProgress {
  final String id; // Document ID: userId_huntId
  final String userId;
  final String huntId;
  final int currentClueOrder; // 0-based index of current clue (0 = first clue)
  final List<String> cluesFound; // List of clue IDs that have been found
  final Map<String, String> evidencePhotos; // clueId -> photo URL evidence
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? timeTakenSeconds; // Total time in seconds (if completed)
  final int? pointsEarned;
  final DateTime? updatedAt;

  UserProgress({
    required this.id,
    required this.userId,
    required this.huntId,
    this.currentClueOrder = 0,
    List<String>? cluesFound,
    Map<String, String>? evidencePhotos,
    this.startedAt,
    this.completedAt,
    this.timeTakenSeconds,
    this.pointsEarned,
    this.updatedAt,
  })  : cluesFound = cluesFound ?? [],
        evidencePhotos = evidencePhotos ?? {};

  bool get isCompleted => completedAt != null;
  int get cluesFoundCount => cluesFound.length;

  // Convert from Firestore document
  factory UserProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProgress(
      id: doc.id,
      userId: data['userId'] ?? '',
      huntId: data['huntId'] ?? '',
      currentClueOrder: data['currentClueOrder'] ?? 0,
      cluesFound: List<String>.from(data['cluesFound'] ?? []),
      evidencePhotos: Map<String, String>.from(data['evidencePhotos'] ?? {}),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      timeTakenSeconds: data['timeTakenSeconds'],
      pointsEarned: data['pointsEarned'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'huntId': huntId,
      'currentClueOrder': currentClueOrder,
      'cluesFound': cluesFound,
      'evidencePhotos': evidencePhotos,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : FieldValue.serverTimestamp(),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'timeTakenSeconds': timeTakenSeconds,
      'pointsEarned': pointsEarned,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserProgress copyWith({
    String? id,
    String? userId,
    String? huntId,
    int? currentClueOrder,
    List<String>? cluesFound,
    Map<String, String>? evidencePhotos,
    DateTime? startedAt,
    DateTime? completedAt,
    int? timeTakenSeconds,
    int? pointsEarned,
    DateTime? updatedAt,
  }) {
    return UserProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      huntId: huntId ?? this.huntId,
      currentClueOrder: currentClueOrder ?? this.currentClueOrder,
      cluesFound: cluesFound ?? this.cluesFound,
      evidencePhotos: evidencePhotos ?? this.evidencePhotos,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      timeTakenSeconds: timeTakenSeconds ?? this.timeTakenSeconds,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper to check if a clue has been found
  bool hasFoundClue(String clueId) {
    return cluesFound.contains(clueId);
  }

  // Helper to add a found clue
  UserProgress addFoundClue(String clueId) {
    if (cluesFound.contains(clueId)) {
      return this; // Already found
    }
    return copyWith(
      cluesFound: [...cluesFound, clueId],
      currentClueOrder: currentClueOrder + 1,
    );
  }

  // Helper to add or update a photo evidence entry
  UserProgress addEvidencePhoto(String clueId, String photoUrl) {
    final updatedPhotos = Map<String, String>.from(evidencePhotos);
    updatedPhotos[clueId] = photoUrl;
    return copyWith(evidencePhotos: updatedPhotos);
  }
}
