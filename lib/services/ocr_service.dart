import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/error_handler.dart';

/// Service for OCR text recognition using Google MLKit
class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  final _textRecognizer = TextRecognizer();

  /// Process image and extract text
  Future<String> processImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        throw Exception('No text found in image');
      }

      return recognizedText.text;
    } catch (e) {
      ErrorHandler.logError('OCRService.processImage', e);
      rethrow;
    }
  }

  /// Process image with detailed blocks (for advanced parsing)
  Future<OCRResult> processImageDetailed(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        throw Exception('No text found in image');
      }

      final lines = <String>[];
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          lines.add(line.text);
        }
      }

      return OCRResult(
        fullText: recognizedText.text,
        lines: lines,
        confidence: _calculateConfidence(recognizedText),
      );
    } catch (e) {
      ErrorHandler.logError('OCRService.processImageDetailed', e);
      rethrow;
    }
  }

  /// Calculate average confidence from recognized text
  double _calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;

    // MLKit doesn't provide confidence scores directly,
    // so we use a heuristic based on text quality
    // This is a simplified approach - in production you might want more sophisticated logic

    int totalChars = 0;
    for (final block in recognizedText.blocks) {
      totalChars += block.text.length;
    }

    // Simple heuristic: if we got text, assume decent confidence
    return totalChars > 0 ? 0.85 : 0.0;
  }

  /// Dispose the text recognizer
  void dispose() {
    _textRecognizer.close();
  }
}

/// Result of OCR processing with additional metadata
class OCRResult {
  final String fullText;
  final List<String> lines;
  final double confidence;

  OCRResult({
    required this.fullText,
    required this.lines,
    required this.confidence,
  });

  bool get isGoodQuality => confidence > 0.7;
  bool get isEmpty => fullText.isEmpty;
}
