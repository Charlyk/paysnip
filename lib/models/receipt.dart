import 'split_item.dart';

/// Represents a scanned receipt with OCR text and parsed items
class Receipt {
  final String id;
  final String userId;
  final String ocrText;
  final List<SplitItem> items;
  final double total;
  final DateTime createdAt;

  Receipt({
    required this.id,
    required this.userId,
    required this.ocrText,
    required this.items,
    required this.total,
    required this.createdAt,
  });

  /// Create from Supabase JSON
  factory Receipt.fromJson(Map<String, dynamic> json) {
    // Parse items from JSONB field
    final parsedData = json['parsed_data'] as Map<String, dynamic>?;
    final itemsList = parsedData != null
        ? (parsedData['items'] as List<dynamic>?)
                ?.map((item) => SplitItem.fromJson(item as Map<String, dynamic>))
                .toList() ??
            []
        : <SplitItem>[];

    return Receipt(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      ocrText: json['ocr_text'] as String? ?? '',
      items: itemsList,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'ocr_text': ocrText,
      'parsed_data': {
        'items': items.map((item) => item.toJson()).toList(),
      },
      'total': total,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with optional modifications
  Receipt copyWith({
    String? id,
    String? userId,
    String? ocrText,
    List<SplitItem>? items,
    double? total,
    DateTime? createdAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ocrText: ocrText ?? this.ocrText,
      items: items ?? this.items,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Calculate total from items
  double calculateTotal() {
    return items.fold(0.0, (sum, item) => sum + item.price);
  }

  /// Validate that total matches sum of items (within small margin for rounding)
  bool get isValid {
    final calculatedTotal = calculateTotal();
    return (total - calculatedTotal).abs() < 0.01;
  }
}
