import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'constants.dart';

/// Centralized error handling and user-friendly error messages
class ErrorHandler {
  // Prevent instantiation
  ErrorHandler._();

  /// Get user-friendly error message from exception
  static String getErrorMessage(dynamic error) {
    if (error == null) {
      return AppConstants.unknownError;
    }

    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return AppConstants.networkError;
    }

    // Auth errors
    if (errorString.contains('invalid login credentials') ||
        errorString.contains('invalid email or password')) {
      return 'Invalid email or password';
    }

    if (errorString.contains('email already registered') ||
        errorString.contains('user already registered')) {
      return 'An account with this email already exists';
    }

    if (errorString.contains('email not confirmed')) {
      return 'Please verify your email before signing in';
    }

    // API errors
    if (errorString.contains('api key')) {
      return 'API configuration error. Please contact support.';
    }

    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (errorString.contains('too many requests') ||
        errorString.contains('rate limit')) {
      return 'Too many requests. Please wait a moment and try again.';
    }

    // Database errors
    if (errorString.contains('not found')) {
      return 'Requested data not found';
    }

    if (errorString.contains('permission denied') ||
        errorString.contains('unauthorized')) {
      return 'You do not have permission to perform this action';
    }

    // OCR/Parsing errors
    if (errorString.contains('ocr')) {
      return AppConstants.ocrError;
    }

    if (errorString.contains('parse') || errorString.contains('parsing')) {
      return AppConstants.parseError;
    }

    // Default error message
    return AppConstants.unknownError;
  }

  /// Log error for debugging
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    developer.log(
      'Error in $context: $error',
      name: 'PaySnip',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Show error snackbar
  static void showErrorSnackbar(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show error dialog
  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic error, {
    String title = 'Error',
    VoidCallback? onRetry,
  }) async {
    final message = getErrorMessage(error);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
