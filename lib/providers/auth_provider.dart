import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';
import '../utils/error_handler.dart';

/// Provider for authentication state and user profile
class AuthProvider with ChangeNotifier {
  final _supabaseService = SupabaseService();

  User? _currentUser;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _init();
  }

  /// Initialize and listen to auth state changes
  void _init() {
    // Get current user
    _currentUser = _supabaseService.getCurrentUser();
    if (_currentUser != null) {
      _loadUserProfile();
    }

    // Listen to auth state changes
    _supabaseService.authStateChanges.listen((authState) {
      _currentUser = authState.session?.user;
      if (_currentUser != null) {
        _loadUserProfile();
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  /// Load user profile from database
  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;

    try {
      _userProfile = await _supabaseService.getProfile(_currentUser!.id);

      // If profile doesn't exist, create one
      if (_userProfile == null) {
        await _createProfile();
      }

      notifyListeners();
    } catch (e) {
      ErrorHandler.logError('AuthProvider._loadUserProfile', e);
    }
  }

  /// Create initial user profile
  Future<void> _createProfile() async {
    if (_currentUser == null) return;

    try {
      final newProfile = UserProfile(
        id: _currentUser!.id,
        scanCount: 0,
        scanResetDate: DateTime.now(),
        isPremium: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _supabaseService.upsertProfile(newProfile);
      _userProfile = newProfile;
      notifyListeners();
    } catch (e) {
      ErrorHandler.logError('AuthProvider._createProfile', e);
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      await _supabaseService.signIn(email, password);
      // Auth state change listener will handle the rest
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError('AuthProvider.signIn', e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign up with email and password
  Future<void> signUp(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      await _supabaseService.signUp(email, password);
      // Auth state change listener will handle the rest
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError('AuthProvider.signUp', e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _error = null;

    try {
      await _supabaseService.signInWithGoogle();
      // Auth state change listener will handle the rest
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError('AuthProvider.signInWithGoogle', e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _supabaseService.signOut();
      _currentUser = null;
      _userProfile = null;
      notifyListeners();
    } catch (e) {
      ErrorHandler.logError('AuthProvider.signOut', e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update payment info
  Future<void> updatePaymentInfo({
    String? venmoUsername,
    String? paypalEmail,
  }) async {
    if (_currentUser == null) return;

    _setLoading(true);

    try {
      await _supabaseService.updatePaymentInfo(
        userId: _currentUser!.id,
        venmoUsername: venmoUsername,
        paypalEmail: paypalEmail,
      );

      // Reload profile
      await _loadUserProfile();
    } catch (e) {
      ErrorHandler.logError('AuthProvider.updatePaymentInfo', e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh user profile
  Future<void> refreshProfile() async {
    await _loadUserProfile();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
