/// Generic cache data model for CRM providers
/// Handles caching with 30-second validity and loading states
class CachedData<T> {
  T? data;
  DateTime? timestamp;
  bool isLoading = false;
  bool isRefreshing = false;
  String? error;

  CachedData({
    this.data,
    this.timestamp,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
  });

  /// Check if cached data is still valid (within 30 seconds)
  bool get isValid {
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp!) < const Duration(seconds: 30);
  }

  /// Check if cache has data
  bool get hasData => data != null;

  /// Mark cache as stale
  void markStale() => timestamp = null;

  /// Clear all cache data
  void clear() {
    data = null;
    timestamp = null;
    error = null;
    isLoading = false;
    isRefreshing = false;
  }
}
