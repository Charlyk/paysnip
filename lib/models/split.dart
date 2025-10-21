import 'person_assignment.dart';

/// Represents a bill split with assignments to people
class Split {
  final String id;
  final String receiptId;
  final String userId;
  final String splitType; // 'even' or 'custom'
  final int? numPeople; // For even splits
  final List<PersonAssignment> assignments;
  final String shareLinkId;
  final DateTime createdAt;

  Split({
    required this.id,
    required this.receiptId,
    required this.userId,
    required this.splitType,
    this.numPeople,
    required this.assignments,
    required this.shareLinkId,
    required this.createdAt,
  });

  /// Create from Supabase JSON
  factory Split.fromJson(Map<String, dynamic> json) {
    // Parse assignments from JSONB field
    final assignmentsList = (json['assignments'] as List<dynamic>?)
            ?.map((assignment) =>
                PersonAssignment.fromJson(assignment as Map<String, dynamic>))
            .toList() ??
        [];

    return Split(
      id: json['id'] as String,
      receiptId: json['receipt_id'] as String,
      userId: json['user_id'] as String,
      splitType: json['split_type'] as String? ?? 'even',
      numPeople: json['num_people'] as int?,
      assignments: assignmentsList,
      shareLinkId: json['share_link_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receipt_id': receiptId,
      'user_id': userId,
      'split_type': splitType,
      'num_people': numPeople,
      'assignments': assignments.map((assignment) => assignment.toJson()).toList(),
      'share_link_id': shareLinkId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with optional modifications
  Split copyWith({
    String? id,
    String? receiptId,
    String? userId,
    String? splitType,
    int? numPeople,
    List<PersonAssignment>? assignments,
    String? shareLinkId,
    DateTime? createdAt,
  }) {
    return Split(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      userId: userId ?? this.userId,
      splitType: splitType ?? this.splitType,
      numPeople: numPeople ?? this.numPeople,
      assignments: assignments ?? this.assignments,
      shareLinkId: shareLinkId ?? this.shareLinkId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get total amount of the split
  double get totalAmount {
    return assignments.fold(0.0, (sum, assignment) => sum + assignment.total);
  }

  /// Check if this is an even split
  bool get isEvenSplit => splitType == 'even';

  /// Check if this is a custom split
  bool get isCustomSplit => splitType == 'custom';
}
