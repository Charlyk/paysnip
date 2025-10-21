import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application constants and environment variables
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // OpenAI Configuration
  static String get openaiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static String get openaiApiUrl =>
      dotenv.env['OPENAI_API_URL'] ?? 'https://api.openai.com/v1/chat/completions';
  static String get openaiModel => dotenv.env['OPENAI_MODEL'] ?? 'gpt-4o-mini';

  // Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // App Configuration
  static const String appName = 'PaySnip';
  static const String appTagline = 'Split bills in seconds';
  
  // Freemium Limits
  static const int freeScansPerMonth = 5;
  
  // Share Link Configuration
  static const String shareLinkBaseUrl = 'https://paysnip.app/split/';
  static const String deepLinkScheme = 'paysnip://';
  
  // Validation
  static const int minPasswordLength = 8;
  static const String venmoUsernamePrefix = '@';
  
  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration ocrTimeout = Duration(seconds: 20);
  
  // Error Messages
  static const String networkError = 'Network error. Please check your connection.';
  static const String unknownError = 'Something went wrong. Please try again.';
  static const String scanLimitReached = 'You\'ve reached your monthly scan limit.';
  static const String ocrError = 'Failed to read receipt. Please try again or enter manually.';
  static const String parseError = 'Failed to parse receipt. Please edit items manually.';
}
