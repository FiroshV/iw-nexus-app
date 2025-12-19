import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/cached_data.dart';
import '../../services/api_service.dart';

/// Provider for caching appointment data with 30-second validity
class AppointmentProvider extends ChangeNotifier {
  /// Separate caches for each view type (assigned, branch, all)
  final Map<String, CachedData<List<Map<String, dynamic>>>> _cache = {
    'assigned': CachedData(),
    'branch': CachedData(),
    'all': CachedData(),
  };

  /// Track pending requests to prevent duplicates
  final Map<String, Future<void>?> _pendingRequests = {};

  /// Get cache for a specific view
  CachedData<List<Map<String, dynamic>>> getCache(String view) {
    return _cache[view] ?? CachedData();
  }

  /// Get appointments with optional search/filter
  List<Map<String, dynamic>> getAppointments(String view,
      {String? searchQuery, String? statusFilter}) {
    final cache = _cache[view];
    if (cache?.data == null) return [];

    var results = cache!.data!;

    // Apply status filter
    if (statusFilter != null && statusFilter.isNotEmpty) {
      results = results
          .where((a) => (a['status'] ?? '').toString() == statusFilter)
          .toList();
    }

    // Apply search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      results = results
          .where((a) {
            final title = (a['title'] ?? '').toString().toLowerCase();
            final customerName =
                (a['customerName'] ?? '').toString().toLowerCase();
            final notes = (a['notes'] ?? '').toString().toLowerCase();
            return title.contains(query) ||
                customerName.contains(query) ||
                notes.contains(query);
          })
          .toList();
    }

    return results;
  }

  /// Fetch appointments with 30-second caching
  Future<void> fetchAppointments({
    required String view,
    bool forceRefresh = false,
  }) async {
    final cache = _cache[view]!;

    // If already fetching this view, return existing Future (deduplication)
    if (_pendingRequests[view] != null) {
      return _pendingRequests[view]!;
    }

    // If cache is valid and not forced refresh, nothing to do
    if (!forceRefresh && cache.isValid && cache.hasData) {
      return;
    }

    // Serve cached data immediately if available
    if (!forceRefresh && cache.hasData && !cache.isLoading) {
      // Show stale data immediately, then refresh in background
      cache.isRefreshing = true;
      notifyListeners();

      _pendingRequests[view] = _fetchAppointmentsInternal(view).then((_) {
        cache.isRefreshing = false;
        _pendingRequests[view] = null;
        notifyListeners();
      }).catchError((e) {
        cache.isRefreshing = false;
        _pendingRequests[view] = null;
        notifyListeners();
      });

      return;
    }

    // No cache - show loading
    cache.isLoading = true;
    cache.error = null;
    notifyListeners();

    _pendingRequests[view] = _fetchAppointmentsInternal(view).then((_) {
      cache.isLoading = false;
      _pendingRequests[view] = null;
      notifyListeners();
    }).catchError((e) {
      cache.isLoading = false;
      _pendingRequests[view] = null;
      notifyListeners();
    });

    return _pendingRequests[view];
  }

  /// Internal fetch logic
  Future<void> _fetchAppointmentsInternal(String view) async {
    final cache = _cache[view]!;

    try {
      final response = await ApiService.get(
        '/crm/appointments?limit=100&view=$view',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final appointments = (data['data'] as List)
            .map((a) => a as Map<String, dynamic>)
            .toList();

        cache.data = appointments;
        cache.timestamp = DateTime.now();
        cache.error = null;
      } else {
        cache.error = _getErrorMessage(response.statusCode);
      }
    } catch (e) {
      cache.error = _getErrorMessage(null, error: e);
    }
  }

  /// Invalidate all caches (marks them as stale)
  void invalidateAll() {
    _cache.forEach((view, cache) {
      cache.markStale();
    });
  }

  /// Clear all caches (called on logout)
  void clear() {
    _cache.forEach((view, cache) {
      cache.clear();
    });
  }

  /// Helper to get error messages
  String _getErrorMessage(int? statusCode, {dynamic error}) {
    if (error != null) {
      final errorStr = error.toString().toLowerCase();
      if (errorStr.contains('socket') || errorStr.contains('connection')) {
        return 'No internet connection. Please check your network.';
      }
      return 'Error loading appointments. Please try again.';
    }

    switch (statusCode) {
      case 404:
        return 'Appointment service not available';
      case 401:
      case 403:
        return 'Access denied. You don\'t have permission to view appointments.';
      case 500:
      case 502:
      case 503:
        return 'Server error. Please try again later.';
      default:
        return 'Failed to load appointments. Please try again.';
    }
  }

  @override
  void dispose() {
    _cache.clear();
    _pendingRequests.clear();
    super.dispose();
  }
}
