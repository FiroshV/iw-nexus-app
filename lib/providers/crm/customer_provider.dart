import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/cached_data.dart';
import '../../models/customer.dart';
import '../../services/api_service.dart';

class CustomerProvider extends ChangeNotifier {
  /// Separate caches for each view type (assigned, branch, all)
  final Map<String, CachedData<List<Customer>>> _cache = {
    'assigned': CachedData(),
    'branch': CachedData(),
    'all': CachedData(),
  };

  /// Track pending requests to prevent duplicates
  final Map<String, Future<void>?> _pendingRequests = {};

  /// Get cache for a specific view
  CachedData<List<Customer>> getCache(String view) {
    return _cache[view] ?? CachedData();
  }

  /// Get customers with optional search filter
  /// Filters are applied locally (fast) on cached data, no API calls made
  List<Customer> getCustomers(String view, {String? searchQuery}) {
    final cache = _cache[view];
    if (cache?.data == null) return [];

    if (searchQuery == null || searchQuery.isEmpty) {
      return cache!.data!;
    }

    final query = searchQuery.toLowerCase();
    return cache!.data!
        .where((c) =>
            c.name.toLowerCase().contains(query) ||
            c.mobileNumber.contains(query) ||
            c.customerId.toLowerCase().contains(query))
        .toList();
  }

  /// Fetch customers with 30-second caching
  /// Shows cached data immediately if valid, refreshes in background if stale
  Future<void> fetchCustomers({
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

      _pendingRequests[view] = _fetchCustomersInternal(view).then((_) {
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

    _pendingRequests[view] = _fetchCustomersInternal(view).then((_) {
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
  Future<void> _fetchCustomersInternal(String view) async {
    final cache = _cache[view]!;

    try {
      final response = await ApiService.get(
        '/crm/customers?limit=500&view=$view',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final customers = (data['data'] as List)
            .map((c) => Customer.fromJson(c as Map<String, dynamic>))
            .toList();

        cache.data = customers;
        cache.timestamp = DateTime.now();
        cache.error = null;
      } else {
        cache.error = _getErrorMessage(response.statusCode);
      }
    } catch (e) {
      cache.error = _getErrorMessage(null, error: e);
    }
  }

  /// Optimistic add customer to cache (called after successful creation)
  void addCustomerOptimistic(Customer customer) {
    _cache.forEach((view, cache) {
      if (cache.data != null) {
        cache.data!.insert(0, customer);
      }
    });
    notifyListeners();
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
      return 'Error loading customers. Please try again.';
    }

    switch (statusCode) {
      case 404:
        return 'Customer service not available';
      case 401:
      case 403:
        return 'Access denied. You don\'t have permission to view customers.';
      case 500:
      case 502:
      case 503:
        return 'Server error. Please try again later.';
      default:
        return 'Failed to load customers. Please try again.';
    }
  }

  @override
  void dispose() {
    _cache.clear();
    _pendingRequests.clear();
    super.dispose();
  }
}
