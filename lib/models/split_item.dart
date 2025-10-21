/// Represents a single item from a receipt
class SplitItem {
  final String name;
  final double price;

  SplitItem({
    required this.name,
    required this.price,
  });

  /// Create from JSON
  factory SplitItem.fromJson(Map<String, dynamic> json) {
    return SplitItem(
      name: json['item'] as String? ?? json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'item': name,
      'price': price,
    };
  }

  /// Create a copy with optional modifications
  SplitItem copyWith({
    String? name,
    double? price,
  }) {
    return SplitItem(
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }

  @override
  String toString() => '$name: \$${price.toStringAsFixed(2)}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          price == other.price;

  @override
  int get hashCode => name.hashCode ^ price.hashCode;
}
