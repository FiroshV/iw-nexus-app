import 'dart:convert';
import '../config/api_config.dart';
import '../config/api_endpoints.dart';
import '../config/http_client_config.dart';
import '../models/gamification_profile.dart';
import '../models/leaderboard_entry.dart';
import 'api_service.dart';

/// Service class for handling gamification-related API calls.
///
/// SIMPLIFIED: Leaderboards only - no points, no badges, no challenges
///
/// This service provides methods for:
/// - Profile management (view profile, update preferences)
/// - Leaderboards (by metric, by branch)
/// - Rankings (user's position for each metric)
/// - Admin exports
class GamificationService {
  GamificationService._();

  // ============================================================================
  // PROFILE ENDPOINTS
  // ============================================================================

  /// Get current user's gamification profile
  static Future<ApiResponse<GamificationProfile>> getMyProfile() async {
    final response = await ApiService.get(ApiEndpoints.gamificationProfile);

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // The profile is nested in data.profile
          final profileData = data['data']['profile'] ?? data['data'];
          return ApiResponse<GamificationProfile>(
            success: true,
            message: data['message'] ?? 'Profile fetched successfully',
            data: GamificationProfile.fromJson(profileData),
          );
        }
        return ApiResponse<GamificationProfile>(
          success: false,
          message: data['message'] ?? 'Failed to fetch profile',
        );
      } catch (e) {
        return ApiResponse<GamificationProfile>(
          success: false,
          message: 'Failed to parse profile data: $e',
        );
      }
    }

    return ApiResponse<GamificationProfile>(
      success: false,
      message: 'Failed to fetch profile',
      statusCode: response.statusCode,
    );
  }

  /// Get gamification summary (profile + rankings)
  static Future<ApiResponse<GamificationSummary>> getSummary() async {
    final response = await ApiService.get(ApiEndpoints.gamificationSummary);

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return ApiResponse<GamificationSummary>(
            success: true,
            message: data['message'] ?? 'Summary fetched successfully',
            data: GamificationSummary.fromJson(data['data']),
          );
        }
        return ApiResponse<GamificationSummary>(
          success: false,
          message: data['message'] ?? 'Failed to fetch summary',
        );
      } catch (e) {
        return ApiResponse<GamificationSummary>(
          success: false,
          message: 'Failed to parse summary data: $e',
        );
      }
    }

    return ApiResponse<GamificationSummary>(
      success: false,
      message: 'Failed to fetch summary',
      statusCode: response.statusCode,
    );
  }

  /// Update user's gamification preferences (just leaderboard visibility)
  static Future<ApiResponse<Map<String, dynamic>>> updatePreferences({
    bool? showOnLeaderboard,
  }) async {
    final body = <String, dynamic>{};
    if (showOnLeaderboard != null) body['showOnLeaderboard'] = showOnLeaderboard;

    final response = await _put(ApiEndpoints.gamificationPreferences, body);
    return response;
  }

  /// Get user's current streak status
  static Future<ApiResponse<Map<String, dynamic>>> getStreak() async {
    final response = await ApiService.get(ApiEndpoints.gamificationStreak);

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return ApiResponse<Map<String, dynamic>>(
            success: true,
            message: data['message'] ?? 'Streak fetched successfully',
            data: data['data'],
          );
        }
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: data['message'] ?? 'Failed to fetch streak',
        );
      } catch (e) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Failed to parse streak data: $e',
        );
      }
    }

    return ApiResponse<Map<String, dynamic>>(
      success: false,
      message: 'Failed to fetch streak',
      statusCode: response.statusCode,
    );
  }

  /// Get profile for a specific user (Admin/Director/Manager only)
  static Future<ApiResponse<GamificationSummary>> getProfileByUserId(
      String userId) async {
    final response = await ApiService.get(
      ApiEndpoints.gamificationProfileByUserId(userId),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return ApiResponse<GamificationSummary>(
            success: true,
            message: data['message'] ?? 'Profile fetched successfully',
            data: GamificationSummary.fromJson(data['data']),
          );
        }
        return ApiResponse<GamificationSummary>(
          success: false,
          message: data['message'] ?? 'Failed to fetch profile',
        );
      } catch (e) {
        return ApiResponse<GamificationSummary>(
          success: false,
          message: 'Failed to parse profile data: $e',
        );
      }
    }

    return ApiResponse<GamificationSummary>(
      success: false,
      message: 'Failed to fetch profile',
      statusCode: response.statusCode,
    );
  }

  // ============================================================================
  // LEADERBOARD ENDPOINTS
  // ============================================================================

  /// Get leaderboard with filters
  static Future<ApiResponse<List<LeaderboardEntry>>> getLeaderboard({
    String metric = 'sales_count',
    String? branchId,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'metric': metric,
      'limit': limit.toString(),
    };
    if (branchId != null) queryParams['branchId'] = branchId;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final endpoint = '${ApiEndpoints.gamificationLeaderboard}?$queryString';

    final response = await ApiService.get(endpoint);

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final entries = (data['data'] as List)
              .map((e) => LeaderboardEntry.fromJson(e))
              .toList();
          return ApiResponse<List<LeaderboardEntry>>(
            success: true,
            message: data['message'] ?? 'Leaderboard fetched successfully',
            data: entries,
          );
        }
        return ApiResponse<List<LeaderboardEntry>>(
          success: false,
          message: data['message'] ?? 'Failed to fetch leaderboard',
        );
      } catch (e) {
        return ApiResponse<List<LeaderboardEntry>>(
          success: false,
          message: 'Failed to parse leaderboard data: $e',
        );
      }
    }

    return ApiResponse<List<LeaderboardEntry>>(
      success: false,
      message: 'Failed to fetch leaderboard',
      statusCode: response.statusCode,
    );
  }

  /// Get current user's rankings across all metrics
  static Future<ApiResponse<Rankings>> getMyRankings() async {
    final response = await ApiService.get(ApiEndpoints.gamificationMyRank);

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return ApiResponse<Rankings>(
            success: true,
            message: data['message'] ?? 'Rankings fetched successfully',
            data: Rankings.fromJson(data['data']),
          );
        }
        return ApiResponse<Rankings>(
          success: false,
          message: data['message'] ?? 'Failed to fetch rankings',
        );
      } catch (e) {
        return ApiResponse<Rankings>(
          success: false,
          message: 'Failed to parse rankings data: $e',
        );
      }
    }

    return ApiResponse<Rankings>(
      success: false,
      message: 'Failed to fetch rankings',
      statusCode: response.statusCode,
    );
  }

  /// Get podium (top 3) for a metric
  static Future<ApiResponse<List<LeaderboardEntry>>> getPodium({
    String metric = 'sales_count',
  }) async {
    return getLeaderboard(metric: metric, limit: 3);
  }

  /// Get branch-specific leaderboard
  static Future<ApiResponse<List<LeaderboardEntry>>> getBranchLeaderboard(
    String branchId, {
    String metric = 'sales_count',
    int limit = 50,
  }) async {
    return getLeaderboard(metric: metric, branchId: branchId, limit: limit);
  }

  // ============================================================================
  // ADMIN ENDPOINTS
  // ============================================================================

  /// Get admin overview stats (Admin/Director only)
  static Future<ApiResponse<Map<String, dynamic>>> getAdminOverview() async {
    final response = await ApiService.get(ApiEndpoints.gamificationAdminOverview);

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return ApiResponse<Map<String, dynamic>>(
            success: true,
            message: data['message'] ?? 'Overview fetched successfully',
            data: data['data'],
          );
        }
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: data['message'] ?? 'Failed to fetch overview',
        );
      } catch (e) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Failed to parse overview data: $e',
        );
      }
    }

    return ApiResponse<Map<String, dynamic>>(
      success: false,
      message: 'Failed to fetch overview',
      statusCode: response.statusCode,
    );
  }

  /// Export leaderboard data as CSV (Admin/Director only)
  static Future<ApiResponse<String>> exportLeaderboard({
    String metric = 'sales_count',
  }) async {
    final endpoint = '${ApiEndpoints.gamificationAdminExport}?metric=$metric';

    final response = await ApiService.get(endpoint);

    if (response.statusCode == 200) {
      // CSV data is returned as plain text
      return ApiResponse<String>(
        success: true,
        message: 'Export successful',
        data: response.body,
      );
    }

    try {
      final data = jsonDecode(response.body);
      return ApiResponse<String>(
        success: false,
        message: data['message'] ?? 'Export failed',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<String>(
        success: false,
        message: 'Export failed',
        statusCode: response.statusCode,
      );
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  static Future<ApiResponse<Map<String, dynamic>>> _put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final token = await ApiService.getToken();
      final response = await HttpClientConfig.client.put(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      return ApiResponse<Map<String, dynamic>>(
        success: data['success'] ?? response.statusCode == 200,
        message: data['message'] ??
            (response.statusCode < 300 ? 'Success' : 'Failed'),
        data: data['data'],
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Request failed: $e',
      );
    }
  }
}
