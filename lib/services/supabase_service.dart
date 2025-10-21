import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/receipt.dart';
import '../models/split.dart';
import '../models/split_item.dart';
import '../models/person_assignment.dart';
import '../utils/constants.dart';

/// Singleton service for Supabase operations
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // ============ AUTHENTICATION ============

  /// Sign in with email and password
  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    return await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: '${AppConstants.deepLinkScheme}auth/callback',
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Get current user
  User? getCurrentUser() {
    return client.auth.currentUser;
  }

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // ============ PROFILE OPERATIONS ============

  /// Get user profile by ID
  Future<UserProfile?> getProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  /// Create or update user profile
  Future<void> upsertProfile(UserProfile profile) async {
    await client.from('profiles').upsert(profile.toJson());
  }

  /// Update payment info
  Future<void> updatePaymentInfo({
    required String userId,
    String? venmoUsername,
    String? paypalEmail,
  }) async {
    await client.from('profiles').update({
      'venmo_username': venmoUsername,
      'paypal_email': paypalEmail,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  // ============ RECEIPT OPERATIONS ============

  /// Save receipt to database
  Future<String> saveReceipt({
    required String userId,
    required String ocrText,
    required List<SplitItem> items,
    required double total,
  }) async {
    final response = await client
        .from('receipts')
        .insert({
          'user_id': userId,
          'ocr_text': ocrText,
          'parsed_data': {
            'items': items.map((item) => item.toJson()).toList(),
          },
          'total': total,
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Get receipt by ID
  Future<Receipt?> getReceipt(String receiptId) async {
    final response = await client
        .from('receipts')
        .select()
        .eq('id', receiptId)
        .maybeSingle();

    if (response == null) return null;
    return Receipt.fromJson(response);
  }

  // ============ SPLIT OPERATIONS ============

  /// Save split to database
  Future<String> saveSplit({
    required String receiptId,
    required String userId,
    required String splitType,
    int? numPeople,
    required List<PersonAssignment> assignments,
    required String shareLinkId,
  }) async {
    final response = await client
        .from('splits')
        .insert({
          'receipt_id': receiptId,
          'user_id': userId,
          'split_type': splitType,
          'num_people': numPeople,
          'assignments': assignments.map((a) => a.toJson()).toList(),
          'share_link_id': shareLinkId,
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Get split by link ID (public access, no auth required)
  Future<Split?> getSplitByLinkId(String linkId) async {
    final response = await client
        .from('splits')
        .select()
        .eq('share_link_id', linkId)
        .maybeSingle();

    if (response == null) return null;
    return Split.fromJson(response);
  }

  /// Get all splits for a user
  Future<List<Split>> getUserSplits(String userId) async {
    final response = await client
        .from('splits')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((split) => Split.fromJson(split))
        .toList();
  }

  /// Get split by ID
  Future<Split?> getSplit(String splitId) async {
    final response = await client
        .from('splits')
        .select()
        .eq('id', splitId)
        .maybeSingle();

    if (response == null) return null;
    return Split.fromJson(response);
  }

  /// Delete split
  Future<void> deleteSplit(String splitId) async {
    await client.from('splits').delete().eq('id', splitId);
  }

  // ============ SCAN LIMIT OPERATIONS ============

  /// Increment user's scan count
  Future<void> incrementScanCount(String userId) async {
    // Get current count
    final profile = await getProfile(userId);
    if (profile == null) return;

    await client.from('profiles').update({
      'scan_count': profile.scanCount + 1,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  /// Reset scan count (called monthly)
  Future<void> resetScanCount(String userId) async {
    await client.from('profiles').update({
      'scan_count': 0,
      'scan_reset_date': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }
}
