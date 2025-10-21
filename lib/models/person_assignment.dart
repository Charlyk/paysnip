import 'split_item.dart';

/// Represents a person's share of a bill with their assigned items
class PersonAssignment {
  final String name;
  final List<SplitItem> items;
  final double total;

  PersonAssignment({
    required this.name,
    required this.items,
    required this.total,
  });

  /// Create from JSON
  factory PersonAssignment.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((item) => SplitItem.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return PersonAssignment(
      name: json['name'] as String? ?? '',
      items: itemsList,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
    };
  }

  /// Create a copy with optional modifications
  PersonAssignment copyWith({
    String? name,
    List<SplitItem>? items,
    double? total,
  }) {
    return PersonAssignment(
      name: name ?? this.name,
      items: items ?? this.items,
      total: total ?? this.total,
    );
  }

  @override
  String toString() {
    final formattedTotal = total.toStringAsFixed(2);
    return '$name owes \$$formattedTotal';
  }
}
