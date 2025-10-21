import '../utils/constants.dart';
import 'supabase_service.dart';

/// Service for managing scan limits and freemium logic
class ScanLimitService {
  static final ScanLimitService _instance = ScanLimitService._internal();
  factory ScanLimitService() => _instance;
  ScanLimitService._internal();

  final _supabaseService = SupabaseService();

  /// Check if user can perform a scan
  Future<bool> canScan(String userId) async {
    final profile = await _supabaseService.getProfile(userId);
    if (profile == null) return false;

    // Premium users have unlimited scans
    if (profile.isPremium) return true;

    // Check if scan count needs to be reset (monthly)
    if (_shouldResetScans(profile.scanResetDate)) {
      await _supabaseService.resetScanCount(userId);
      return true;
    }

    // Check if user has scans remaining
    return profile.scanCount < AppConstants.freeScansPerMonth;
  }

  /// Get number of scans remaining for user
  Future<int> getScansRemaining(String userId) async {
    final profile = await _supabaseService.getProfile(userId);
    if (profile == null) return 0;

    // Premium users have unlimited scans
    if (profile.isPremium) return 999;

    // Check if scan count needs to be reset
    if (_shouldResetScans(profile.scanResetDate)) {
      await _supabaseService.resetScanCount(userId);
      return AppConstants.freeScansPerMonth;
    }

    final remaining = AppConstants.freeScansPerMonth - profile.scanCount;
    return remaining > 0 ? remaining : 0;
  }

  /// Increment user's scan count
  Future<void> incrementScanCount(String userId) async {
    await _supabaseService.incrementScanCount(userId);
  }

  /// Check if user is premium
  Future<bool> isPremium(String userId) async {
    final profile = await _supabaseService.getProfile(userId);
    return profile?.isPremium ?? false;
  }

  /// Get scan reset date
  Future<DateTime?> getResetDate(String userId) async {
    final profile = await _supabaseService.getProfile(userId);
    if (profile == null) return null;

    // If scans should be reset, return now + 1 month
    if (_shouldResetScans(profile.scanResetDate)) {
      return _getNextResetDate(DateTime.now());
    }

    return _getNextResetDate(profile.scanResetDate);
  }

  /// Check if scans should be reset (monthly reset)
  bool _shouldResetScans(DateTime lastResetDate) {
    final now = DateTime.now();
    final daysSinceReset = now.difference(lastResetDate).inDays;

    // Reset if more than 30 days have passed
    return daysSinceReset >= 30;
  }

  /// Get next reset date (30 days from given date)
  DateTime _getNextResetDate(DateTime fromDate) {
    return fromDate.add(const Duration(days: 30));
  }

  /// Get scan usage summary for user
  Future<ScanUsage> getScanUsage(String userId) async {
    final profile = await _supabaseService.getProfile(userId);
    if (profile == null) {
      return ScanUsage(
        scansUsed: 0,
        scansLimit: AppConstants.freeScansPerMonth,
        scansRemaining: AppConstants.freeScansPerMonth,
        resetDate: DateTime.now().add(const Duration(days: 30)),
        isPremium: false,
      );
    }

    // Check if reset needed
    if (_shouldResetScans(profile.scanResetDate)) {
      await _supabaseService.resetScanCount(userId);
      return ScanUsage(
        scansUsed: 0,
        scansLimit: AppConstants.freeScansPerMonth,
        scansRemaining: AppConstants.freeScansPerMonth,
        resetDate: _getNextResetDate(DateTime.now()),
        isPremium: profile.isPremium,
      );
    }

    final scansUsed = profile.scanCount;
    final scansLimit = profile.isPremium ? 999 : AppConstants.freeScansPerMonth;
    final scansRemaining = profile.isPremium
        ? 999
        : (AppConstants.freeScansPerMonth - scansUsed).clamp(0, AppConstants.freeScansPerMonth);

    return ScanUsage(
      scansUsed: scansUsed,
      scansLimit: scansLimit,
      scansRemaining: scansRemaining,
      resetDate: _getNextResetDate(profile.scanResetDate),
      isPremium: profile.isPremium,
    );
  }
}

/// Scan usage information
class ScanUsage {
  final int scansUsed;
  final int scansLimit;
  final int scansRemaining;
  final DateTime resetDate;
  final bool isPremium;

  ScanUsage({
    required this.scansUsed,
    required this.scansLimit,
    required this.scansRemaining,
    required this.resetDate,
    required this.isPremium,
  });

  /// Check if user has reached limit
  bool get hasReachedLimit => !isPremium && scansRemaining <= 0;

  /// Get usage percentage (0.0 to 1.0)
  double get usagePercentage => isPremium ? 0.0 : scansUsed / scansLimit;

  /// Get display string for usage
  String get usageDisplay => isPremium
      ? 'Unlimited'
      : '$scansRemaining/$scansLimit scans remaining';
}
