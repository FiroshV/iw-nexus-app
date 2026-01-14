import 'package:flutter/material.dart';
import '../models/cached_data.dart';
import '../models/gamification_profile.dart';
import '../models/leaderboard_entry.dart';
import '../services/gamification_service.dart';

/// Provider for managing gamification state with 30-second cache validity.
///
/// SIMPLIFIED: Leaderboards only - no points, no badges, no challenges
///
/// This provider handles:
/// - User profile and summary
/// - Leaderboards (with metric/branch filters)
/// - User ranks for different metrics
class GamificationProvider extends ChangeNotifier {
  // =====================
  // CACHED DATA
  // =====================

  /// Cache for gamification summary (profile + rankings)
  CachedData<GamificationSummary> _summary = CachedData();

  /// Cache for user's full profile
  CachedData<GamificationProfile> _profile = CachedData();

  /// Cache for user's rank across all metrics
  CachedData<Rankings> _myRankings = CachedData();

  /// Cache for leaderboard entries (keyed by metric)
  final Map<String, CachedData<List<LeaderboardEntry>>> _leaderboards = {};

  /// Track pending requests to prevent duplicates
  final Map<String, Future<void>?> _pendingRequests = {};

  /// Current leaderboard filter settings
  String _currentMetric = 'sales_count';
  String? _currentBranchId;

  // =====================
  // GETTERS - Summary & Profile
  // =====================

  GamificationSummary? get summary => _summary.data;
  bool get isSummaryLoading => _summary.isLoading;
  bool get hasSummary => _summary.hasData;
  String? get summaryError => _summary.error;

  GamificationProfile? get profile => _profile.data;
  bool get isProfileLoading => _profile.isLoading;
  bool get hasProfile => _profile.hasData;
  String? get profileError => _profile.error;

  /// Convenience getter for quick access to profile from summary
  GamificationProfile? get quickProfile =>
      _summary.data?.profile ?? _profile.data;

  /// Get user's stats
  GamificationStats? get stats => quickProfile?.stats;

  /// Get user's current streak count
  int get currentStreakCount => quickProfile?.currentStreak.count ?? 0;

  /// Get user's current streak type
  String? get currentStreakType => quickProfile?.currentStreak.type;

  // =====================
  // GETTERS - Rankings
  // =====================

  Rankings? get myRankings => _myRankings.data ?? _summary.data?.rankings;
  bool get isMyRankingsLoading => _myRankings.isLoading;
  bool get hasMyRankings => _myRankings.hasData || _summary.hasData;

  /// Get sales count rank
  int? get salesCountRank => myRankings?.salesCount.rank;

  /// Get sales amount rank
  int? get salesAmountRank => myRankings?.salesAmount.rank;

  /// Get activities rank
  int? get activitiesRank => myRankings?.activities.rank;

  // =====================
  // GETTERS - Leaderboard
  // =====================

  String get currentMetric => _currentMetric;
  String? get currentBranchId => _currentBranchId;

  /// Get leaderboard for current metric
  List<LeaderboardEntry> get leaderboard {
    final key = _getLeaderboardKey(_currentMetric, _currentBranchId);
    return _leaderboards[key]?.data ?? [];
  }

  /// Check if leaderboard is loading
  bool get isLeaderboardLoading {
    final key = _getLeaderboardKey(_currentMetric, _currentBranchId);
    return _leaderboards[key]?.isLoading ?? false;
  }

  /// Check if leaderboard has data
  bool get hasLeaderboard {
    final key = _getLeaderboardKey(_currentMetric, _currentBranchId);
    return _leaderboards[key]?.hasData ?? false;
  }

  // =====================
  // SUMMARY & PROFILE METHODS
  // =====================

  /// Fetch gamification summary (profile + rankings)
  Future<void> fetchSummary({bool forceRefresh = false}) async {
    const cacheKey = 'summary';

    if (_pendingRequests[cacheKey] != null) {
      return _pendingRequests[cacheKey]!;
    }

    if (!forceRefresh && _summary.isValid && _summary.hasData) {
      return;
    }

    _summary.isLoading = true;
    notifyListeners();

    _pendingRequests[cacheKey] = _fetchSummaryInternal();

    try {
      await _pendingRequests[cacheKey];
    } finally {
      _pendingRequests[cacheKey] = null;
    }
  }

  Future<void> _fetchSummaryInternal() async {
    try {
      debugPrint('GamificationProvider: Fetching summary...');
      final response = await GamificationService.getSummary();

      if (response.success && response.data != null) {
        debugPrint('GamificationProvider: Summary fetched successfully');
        _summary = CachedData(data: response.data, timestamp: DateTime.now());
      } else {
        debugPrint('GamificationProvider: Failed to fetch summary');
        _summary.error = response.message;
      }
    } catch (e) {
      debugPrint('GamificationProvider: Error fetching summary: $e');
      _summary.error = e.toString();
    } finally {
      _summary.isLoading = false;
      _summary.isRefreshing = false;
      notifyListeners();
    }
  }

  /// Fetch full profile
  Future<void> fetchProfile({bool forceRefresh = false}) async {
    const cacheKey = 'profile';

    if (_pendingRequests[cacheKey] != null) {
      return _pendingRequests[cacheKey]!;
    }

    if (!forceRefresh && _profile.isValid && _profile.hasData) {
      return;
    }

    _profile.isLoading = true;
    notifyListeners();

    _pendingRequests[cacheKey] = _fetchProfileInternal();

    try {
      await _pendingRequests[cacheKey];
    } finally {
      _pendingRequests[cacheKey] = null;
    }
  }

  Future<void> _fetchProfileInternal() async {
    try {
      final response = await GamificationService.getMyProfile();

      if (response.success && response.data != null) {
        _profile = CachedData(data: response.data, timestamp: DateTime.now());
      } else {
        _profile.error = response.message;
      }
    } catch (e) {
      _profile.error = e.toString();
    } finally {
      _profile.isLoading = false;
      _profile.isRefreshing = false;
      notifyListeners();
    }
  }

  /// Update user preferences (just leaderboard visibility)
  Future<bool> updatePreferences({bool? showOnLeaderboard}) async {
    try {
      final response = await GamificationService.updatePreferences(
        showOnLeaderboard: showOnLeaderboard,
      );

      if (response.success) {
        // Refresh profile to get updated preferences
        await fetchProfile(forceRefresh: true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating preferences: $e');
      return false;
    }
  }

  // =====================
  // RANKINGS METHODS
  // =====================

  /// Fetch user's rank across all metrics
  Future<void> fetchMyRankings({bool forceRefresh = false}) async {
    const cacheKey = 'myRankings';

    if (_pendingRequests[cacheKey] != null) {
      return _pendingRequests[cacheKey]!;
    }

    if (!forceRefresh && _myRankings.isValid && _myRankings.hasData) {
      return;
    }

    _myRankings.isLoading = true;
    notifyListeners();

    _pendingRequests[cacheKey] = _fetchMyRankingsInternal();

    try {
      await _pendingRequests[cacheKey];
    } finally {
      _pendingRequests[cacheKey] = null;
    }
  }

  Future<void> _fetchMyRankingsInternal() async {
    try {
      final response = await GamificationService.getMyRankings();

      if (response.success && response.data != null) {
        _myRankings = CachedData(data: response.data, timestamp: DateTime.now());
      } else {
        _myRankings.error = response.message;
      }
    } catch (e) {
      _myRankings.error = e.toString();
    } finally {
      _myRankings.isLoading = false;
      _myRankings.isRefreshing = false;
      notifyListeners();
    }
  }

  // =====================
  // LEADERBOARD METHODS
  // =====================

  /// Set leaderboard filters
  void setLeaderboardFilters({
    String? metric,
    String? branchId,
  }) {
    bool changed = false;

    if (metric != null && metric != _currentMetric) {
      _currentMetric = metric;
      changed = true;
    }
    if (branchId != _currentBranchId) {
      _currentBranchId = branchId;
      changed = true;
    }

    if (changed) {
      notifyListeners();
      // Fetch new leaderboard with updated filters
      fetchLeaderboard(forceRefresh: true);
    }
  }

  /// Fetch leaderboard with current filters
  Future<void> fetchLeaderboard({bool forceRefresh = false}) async {
    final key = _getLeaderboardKey(_currentMetric, _currentBranchId);

    if (_pendingRequests[key] != null) {
      return _pendingRequests[key]!;
    }

    if (!forceRefresh &&
        _leaderboards[key]?.isValid == true &&
        _leaderboards[key]?.hasData == true) {
      return;
    }

    _leaderboards[key] ??= CachedData();
    _leaderboards[key]!.isLoading = true;
    notifyListeners();

    _pendingRequests[key] = _fetchLeaderboardInternal(key);

    try {
      await _pendingRequests[key];
    } finally {
      _pendingRequests[key] = null;
    }
  }

  Future<void> _fetchLeaderboardInternal(String key) async {
    try {
      final response = await GamificationService.getLeaderboard(
        metric: _currentMetric,
        branchId: _currentBranchId,
      );

      if (response.success && response.data != null) {
        _leaderboards[key] =
            CachedData(data: response.data, timestamp: DateTime.now());
      } else {
        _leaderboards[key]!.error = response.message;
      }
    } catch (e) {
      _leaderboards[key]!.error = e.toString();
    } finally {
      _leaderboards[key]!.isLoading = false;
      _leaderboards[key]!.isRefreshing = false;
      notifyListeners();
    }
  }

  String _getLeaderboardKey(String metric, String? branchId) {
    return '$metric|${branchId ?? 'all'}';
  }

  // =====================
  // INITIALIZATION & UTILITY
  // =====================

  /// Initialize gamification data (call on dashboard load)
  Future<void> initialize() async {
    await Future.wait([
      fetchSummary(),
      fetchLeaderboard(),
    ]);
  }

  /// Refresh all gamification data
  Future<void> refreshAll() async {
    await Future.wait([
      fetchSummary(forceRefresh: true),
      fetchMyRankings(forceRefresh: true),
      fetchLeaderboard(forceRefresh: true),
    ]);
  }

  /// Clear all cached data
  void clearAll() {
    _summary = CachedData();
    _profile = CachedData();
    _myRankings = CachedData();
    _leaderboards.clear();
    notifyListeners();
  }

  /// Clear specific caches
  void clearSummary() {
    _summary = CachedData();
    notifyListeners();
  }

  void clearProfile() {
    _profile = CachedData();
    notifyListeners();
  }

  void clearLeaderboards() {
    _leaderboards.clear();
    notifyListeners();
  }
}
