import 'package:cloud_firestore/cloud_firestore.dart';

class Hunt {
  final String id;
  final String name;
  final String description;
  final String difficulty; // 'easy', 'medium', 'hard', 'nightmare'
  final int clueCount;
  final List<String> clueIds;
  final bool isAvailable;
  final String? estimatedTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Hunt({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.clueCount,
    required this.clueIds,
    this.isAvailable = true,
    this.estimatedTime,
    this.createdAt,
    this.updatedAt,
  });

  // Convert from Firestore document
  factory Hunt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Hunt(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      difficulty: data['difficulty'] ?? 'medium',
      clueCount: data['clueCount'] ?? 0,
      clueIds: List<String>.from(data['clueIds'] ?? []),
      isAvailable: data['isAvailable'] ?? true,
      estimatedTime: data['estimatedTime'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'difficulty': difficulty,
      'clueCount': clueCount,
      'clueIds': clueIds,
      'isAvailable': isAvailable,
      'estimatedTime': estimatedTime,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Hunt copyWith({
    String? id,
    String? name,
    String? description,
    String? difficulty,
    int? clueCount,
    List<String>? clueIds,
    bool? isAvailable,
    String? estimatedTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Hunt(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      clueCount: clueCount ?? this.clueCount,
      clueIds: clueIds ?? this.clueIds,
      isAvailable: isAvailable ?? this.isAvailable,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
