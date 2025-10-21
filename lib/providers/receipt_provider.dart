import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/split_item.dart';
import '../models/receipt.dart';
import '../services/ocr_service.dart';
import '../services/openai_service.dart';
import '../services/supabase_service.dart';
import '../utils/error_handler.dart';

/// Provider for receipt capture and parsing
class ReceiptProvider with ChangeNotifier {
  final _ocrService = OCRService();
  final _openaiService = OpenAIService();
  final _supabaseService = SupabaseService();

  File? _capturedImage;
  String? _ocrText;
  List<SplitItem> _items = [];
  double _total = 0.0;
  Receipt? _currentReceipt;

  bool _isProcessing = false;
  String? _error;

  File? get capturedImage => _capturedImage;
  String? get ocrText => _ocrText;
  List<SplitItem> get items => _items;
  double get total => _total;
  Receipt? get currentReceipt => _currentReceipt;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  bool get hasItems => _items.isNotEmpty;

  /// Set captured image
  void setCapturedImage(File image) {
    _capturedImage = image;
    notifyListeners();
  }

  /// Process image with OCR
  Future<void> processImage(File imageFile) async {
    _setProcessing(true);
    _error = null;

    try {
      // Extract text using OCR
      _ocrText = await _ocrService.processImage(imageFile);
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError('ReceiptProvider.processImage', e);
      rethrow;
    } finally {
      _setProcessing(false);
    }
  }

  /// Parse OCR text with OpenAI
  Future<void> parseReceipt(String text) async {
    _setProcessing(true);
    _error = null;

    try {
      final parsedReceipt = await _openaiService.parseReceipt(text);

      _items = parsedReceipt.items;
      _total = parsedReceipt.total;
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError('ReceiptProvider.parseReceipt', e);
      rethrow;
    } finally {
      _setProcessing(false);
    }
  }

  /// Complete flow: OCR + Parse
  Future<void> processAndParse(File imageFile) async {
    await processImage(imageFile);
    if (_ocrText != null) {
      await parseReceipt(_ocrText!);
    }
  }

  /// Add item manually
  void addItem(SplitItem item) {
    _items.add(item);
    _recalculateTotal();
    notifyListeners();
  }

  /// Update item
  void updateItem(int index, SplitItem item) {
    if (index >= 0 && index < _items.length) {
      _items[index] = item;
      _recalculateTotal();
      notifyListeners();
    }
  }

  /// Remove item
  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      _recalculateTotal();
      notifyListeners();
    }
  }

  /// Update OCR text manually
  void updateOcrText(String text) {
    _ocrText = text;
    notifyListeners();
  }

  /// Set items manually
  void setItems(List<SplitItem> items) {
    _items = items;
    _recalculateTotal();
    notifyListeners();
  }

  /// Set total manually
  void setTotal(double total) {
    _total = total;
    notifyListeners();
  }

  /// Recalculate total from items
  void _recalculateTotal() {
    _total = _items.fold(0.0, (sum, item) => sum + item.price);
  }

  /// Save receipt to database
  Future<String> saveReceipt(String userId) async {
    _setProcessing(true);
    _error = null;

    try {
      if (_items.isEmpty) {
        throw Exception('No items to save');
      }

      final receiptId = await _supabaseService.saveReceipt(
        userId: userId,
        ocrText: _ocrText ?? '',
        items: _items,
        total: _total,
      );

      // Load the saved receipt
      _currentReceipt = await _supabaseService.getReceipt(receiptId);
      notifyListeners();

      return receiptId;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError('ReceiptProvider.saveReceipt', e);
      rethrow;
    } finally {
      _setProcessing(false);
    }
  }

  /// Clear all receipt data
  void clear() {
    _capturedImage = null;
    _ocrText = null;
    _items = [];
    _total = 0.0;
    _currentReceipt = null;
    _error = null;
    notifyListeners();
  }

  void _setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
