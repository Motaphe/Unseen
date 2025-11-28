import 'package:cloud_firestore/cloud_firestore.dart';

class Clue {
  final String id;
  final String huntId;
  final int order; // Order in the hunt sequence (1, 2, 3, ...)
  final String hint; // Short hint shown initially
  final String fullHint; // More detailed hint
  final String narrative; // Story text shown when clue is found
  final String? arModelUrl; // URL to AR model in Firebase Storage
  final String? arModelId; // Identifier for AR model
  final String? qrCode; // Unique QR code value for this clue
  final String? locationHint; // Optional guidance for where to place/find the QR
  final bool requiresPhoto; // Whether player must capture a photo after scan
  final String? photoUrl; // URL to photo taken when clue was found
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Clue({
    required this.id,
    required this.huntId,
    required this.order,
    required this.hint,
    required this.fullHint,
    required this.narrative,
    this.arModelUrl,
    this.arModelId,
    this.qrCode,
    this.locationHint,
    this.requiresPhoto = true,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  // Convert from Firestore document
  factory Clue.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Clue(
      id: doc.id,
      huntId: data['huntId'] ?? '',
      order: data['order'] ?? 0,
      hint: data['hint'] ?? '',
      fullHint: data['fullHint'] ?? '',
      narrative: data['narrative'] ?? '',
      arModelUrl: data['arModelUrl'],
      arModelId: data['arModelId'],
      qrCode: data['qrCode'],
      locationHint: data['locationHint'],
      requiresPhoto: data['requiresPhoto'] ?? true,
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'huntId': huntId,
      'order': order,
      'hint': hint,
      'fullHint': fullHint,
      'narrative': narrative,
      'arModelUrl': arModelUrl,
      'arModelId': arModelId,
      'qrCode': qrCode,
      'locationHint': locationHint,
      'requiresPhoto': requiresPhoto,
      'photoUrl': photoUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Clue copyWith({
    String? id,
    String? huntId,
    int? order,
    String? hint,
    String? fullHint,
    String? narrative,
    String? arModelUrl,
    String? arModelId,
    String? qrCode,
    String? locationHint,
    bool? requiresPhoto,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Clue(
      id: id ?? this.id,
      huntId: huntId ?? this.huntId,
      order: order ?? this.order,
      hint: hint ?? this.hint,
      fullHint: fullHint ?? this.fullHint,
      narrative: narrative ?? this.narrative,
      arModelUrl: arModelUrl ?? this.arModelUrl,
      arModelId: arModelId ?? this.arModelId,
      qrCode: qrCode ?? this.qrCode,
      locationHint: locationHint ?? this.locationHint,
      requiresPhoto: requiresPhoto ?? this.requiresPhoto,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
