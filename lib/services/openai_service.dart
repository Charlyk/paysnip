import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/split_item.dart';
import '../utils/constants.dart';
import '../utils/error_handler.dart';

/// Service for OpenAI API integration
class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  factory OpenAIService() => _instance;
  OpenAIService._internal();

  /// Parse OCR text into structured receipt data
  Future<ParsedReceipt> parseReceipt(String ocrText) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.openaiApiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppConstants.openaiApiKey}',
            },
            body: jsonEncode({
              'model': AppConstants.openaiModel,
              'messages': [
                {
                  'role': 'system',
                  'content': _getSystemPrompt(),
                },
                {
                  'role': 'user',
                  'content': ocrText,
                },
              ],
              'response_format': {'type': 'json_object'},
              'temperature': 0.1, // Low temperature for consistent parsing
            }),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        final parsedData = jsonDecode(content) as Map<String, dynamic>;

        return _parsedReceiptFromJson(parsedData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('OpenAI API error: ${errorData['error']['message']}');
      }
    } catch (e) {
      ErrorHandler.logError('OpenAIService.parseReceipt', e);
      rethrow;
    }
  }

  /// System prompt for receipt parsing
  String _getSystemPrompt() {
    return '''You are a receipt parser. Extract all items and prices from the receipt text.

Return a JSON object with this exact structure:
{
  "items": [
    {"item": "Item Name", "price": 12.99},
    {"item": "Another Item", "price": 5.50}
  ],
  "total": 18.49
}

Rules:
1. Extract each individual item with its price
2. Prices must be numbers (not strings)
3. Do not include tax or tip as separate items - they are part of the total
4. The total should match the final bill amount
5. If you see quantity × price, calculate the total for that item
6. Ignore non-item text like store name, address, date, payment method
7. If the receipt is unclear or cannot be parsed, return empty items array and 0 total
8. Common item names: food items, drinks, etc. Common price formats: \$X.XX or X.XX

Example input:
"Burger King
Whopper 8.99
Fries 3.49
Coke 2.50
Subtotal 14.98
Tax 1.20
Total 16.18"

Example output:
{
  "items": [
    {"item": "Whopper", "price": 8.99},
    {"item": "Fries", "price": 3.49},
    {"item": "Coke", "price": 2.50}
  ],
  "total": 16.18
}''';
  }

  /// Parse the JSON response from OpenAI
  ParsedReceipt _parsedReceiptFromJson(Map<String, dynamic> json) {
    final items = <SplitItem>[];
    final itemsList = json['items'] as List<dynamic>?;

    if (itemsList != null) {
      for (final item in itemsList) {
        try {
          items.add(SplitItem.fromJson(item as Map<String, dynamic>));
        } catch (e) {
          ErrorHandler.logError('OpenAIService._parsedReceiptFromJson', e);
          // Skip invalid items
          continue;
        }
      }
    }

    final total = (json['total'] as num?)?.toDouble() ?? 0.0;

    return ParsedReceipt(items: items, total: total);
  }
}

/// Result of receipt parsing
class ParsedReceipt {
  final List<SplitItem> items;
  final double total;

  ParsedReceipt({
    required this.items,
    required this.total,
  });

  bool get isEmpty => items.isEmpty;
  bool get isValid => items.isNotEmpty && total > 0;
}
