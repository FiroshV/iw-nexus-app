import 'package:flutter/material.dart';
import '../models/cached_data.dart';
import '../models/incentive_template.dart';
import '../models/employee_incentive.dart';
import '../services/incentive_service.dart';

/// Provider for caching incentive data with 30-second validity
class IncentiveProvider extends ChangeNotifier {
  // =====================
  // CACHED DATA
  // =====================

  /// Cache for my incentive
  CachedData<EmployeeIncentive> _myIncentive = CachedData();

  /// Cache for templates
  CachedData<List<IncentiveTemplate>> _templates = CachedData();

  /// Cache for assignments
  CachedData<List<EmployeeIncentive>> _assignments = CachedData();

  /// Cache for pending promotions
  CachedData<List<EmployeeIncentive>> _pendingPromotions = CachedData();

  /// Track pending requests to prevent duplicates
  final Map<String, Future<void>?> _pendingRequests = {};

  /// Track if template is being fetched
  bool _isTemplateLoading = false;

  // =====================
  // GETTERS
  // =====================

  EmployeeIncentive? get myIncentive => _myIncentive.data;
  bool get isMyIncentiveLoading => _myIncentive.isLoading;
  bool get hasMyIncentive => _myIncentive.hasData;
  String? get myIncentiveError => _myIncentive.error;
  bool get isTemplateLoading => _isTemplateLoading;

  List<IncentiveTemplate> get templates => _templates.data ?? [];
  bool get isTemplatesLoading => _templates.isLoading;
  bool get hasTemplates => _templates.hasData;

  List<EmployeeIncentive> get assignments => _assignments.data ?? [];
  bool get isAssignmentsLoading => _assignments.isLoading;
  bool get hasAssignments => _assignments.hasData;

  List<EmployeeIncentive> get pendingPromotions => _pendingPromotions.data ?? [];
  bool get isPendingPromotionsLoading => _pendingPromotions.isLoading;
  bool get hasPendingPromotions => _pendingPromotions.hasData;
  int get pendingPromotionsCount => _pendingPromotions.data?.length ?? 0;

  // =====================
  // MY INCENTIVE METHODS
  // =====================

  /// Fetch current user's incentive
  Future<void> fetchMyIncentive({bool forceRefresh = false}) async {
    const cacheKey = 'myIncentive';

    // Prevent duplicate requests
    if (_pendingRequests[cacheKey] != null) {
      return _pendingRequests[cacheKey]!;
    }

    // If cache is valid and not forced refresh, nothing to do
    if (!forceRefresh && _myIncentive.isValid && _myIncentive.hasData) {
      return;
    }

    _myIncentive.isLoading = true;
    notifyListeners();

    _pendingRequests[cacheKey] = _fetchMyIncentiveInternal();

    try {
      await _pendingRequests[cacheKey];
    } finally {
      _pendingRequests[cacheKey] = null;
    }
  }

  Future<void> _fetchMyIncentiveInternal() async {
    try {
      debugPrint('🔄 IncentiveProvider: Fetching my incentive...');
      final response = await IncentiveService.getMyIncentive();

      debugPrint('📡 IncentiveProvider: Response received');
      debugPrint('   Success: ${response.success}');
      debugPrint('   Has data: ${response.data != null}');
      debugPrint('   Message: ${response.message}');

      if (response.success && response.data != null) {
        debugPrint('✅ IncentiveProvider: Setting incentive data');
        _myIncentive = CachedData(data: response.data);
        // Fetch template in background if it's not populated
        _fetchAndPopulateTemplate();
      } else {
        debugPrint('⚠️ IncentiveProvider: Failed to fetch incentive');
        if (response.error != null) {
          debugPrint('   Error type: ${response.error.runtimeType}');
          debugPrint('   Error details: ${response.error}');
        }

        _myIncentive.error = response.message ?? 'Unknown error';
      }
    } catch (e, stack) {
      debugPrint('❌ IncentiveProvider: Exception in _fetchMyIncentiveInternal');
      debugPrint('   Error: $e');
      debugPrint('   Stack: $stack');

      _myIncentive.error = e.toString();
    } finally {
      _myIncentive.isLoading = false;
      _myIncentive.isRefreshing = false;
      notifyListeners();

      debugPrint('🏁 IncentiveProvider: Fetch complete');
      debugPrint('   Has data: ${_myIncentive.hasData}');
      debugPrint('   Is loading: ${_myIncentive.isLoading}');
      debugPrint('   Error: ${_myIncentive.error}');
    }
  }

  /// Fetch template if not populated
  Future<void> _fetchAndPopulateTemplate() async {
    if (_myIncentive.data == null) return;

    final incentive = _myIncentive.data!;

    // Check if template needs to be fetched
    if (incentive.currentTemplate == null &&
        incentive.currentTemplateId.isNotEmpty) {
      _isTemplateLoading = true;
      notifyListeners();

      try {
        debugPrint('🔄 IncentiveProvider: Fetching template ${incentive.currentTemplateId}...');

        // Fetch template by ID
        final templateResponse = await IncentiveService.getTemplateById(
          incentive.currentTemplateId,
        );

        if (templateResponse.success && templateResponse.data != null) {
          debugPrint('✅ IncentiveProvider: Template fetched successfully');

          // Update incentive with fetched template
          _myIncentive.data = incentive.copyWith(
            currentTemplate: templateResponse.data,
          );
        } else {
          debugPrint('⚠️ IncentiveProvider: Failed to fetch template');
          debugPrint('   Message: ${templateResponse.message}');
        }
      } catch (e) {
        debugPrint('❌ IncentiveProvider: Error fetching template: $e');
      } finally {
        _isTemplateLoading = false;
        notifyListeners();
      }
    }
  }

  /// Clear my incentive cache
  void clearMyIncentive() {
    _myIncentive = CachedData();
    notifyListeners();
  }

  // =====================
  // TEMPLATE METHODS
  // =====================

  /// Fetch all templates
  Future<void> fetchTemplates({bool forceRefresh = false}) async {
    const cacheKey = 'templates';

    if (_pendingRequests[cacheKey] != null) {
      return _pendingRequests[cacheKey]!;
    }

    if (!forceRefresh && _templates.isValid && _templates.hasData) {
      return;
    }

    _templates.isLoading = true;
    notifyListeners();

    _pendingRequests[cacheKey] = _fetchTemplatesInternal();

    try {
      await _pendingRequests[cacheKey];
    } finally {
      _pendingRequests[cacheKey] = null;
    }
  }

  Future<void> _fetchTemplatesInternal() async {
    try {
      final response = await IncentiveService.getTemplates();

      if (response.success && response.data != null) {
        _templates = CachedData(data: response.data);
      } else {
        _templates.error = response.message;
      }
    } catch (e) {
      _templates.error = e.toString();
    } finally {
      _templates.isLoading = false;
      _templates.isRefreshing = false;
      notifyListeners();
    }
  }

  /// Get a single template by ID
  IncentiveTemplate? getTemplateById(String id) {
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear templates cache
  void clearTemplates() {
    _templates = CachedData();
    notifyListeners();
  }

  // =====================
  // ASSIGNMENT METHODS
  // =====================

  /// Fetch all assignments
  Future<void> fetchAssignments({
    bool forceRefresh = false,
    String? search,
    String? templateId,
    bool? hasPromotion,
  }) async {
    const cacheKey = 'assignments';

    if (_pendingRequests[cacheKey] != null) {
      return _pendingRequests[cacheKey]!;
    }

    if (!forceRefresh && _assignments.isValid && _assignments.hasData) {
      return;
    }

    _assignments.isLoading = true;
    notifyListeners();

    _pendingRequests[cacheKey] = _fetchAssignmentsInternal(
      search: search,
      templateId: templateId,
      hasPromotion: hasPromotion,
    );

    try {
      await _pendingRequests[cacheKey];
    } finally {
      _pendingRequests[cacheKey] = null;
    }
  }

  Future<void> _fetchAssignmentsInternal({
    String? search,
    String? templateId,
    bool? hasPromotion,
  }) async {
    try {
      final response = await IncentiveService.getAssignments(
        search: search,
        templateId: templateId,
        hasPromotion: hasPromotion,
      );

      if (response.success && response.data != null) {
        _assignments = CachedData(data: response.data);
      } else {
        _assignments.error = response.message;
      }
    } catch (e) {
      _assignments.error = e.toString();
    } finally {
      _assignments.isLoading = false;
      _assignments.isRefreshing = false;
      notifyListeners();
    }
  }

  /// Clear assignments cache
  void clearAssignments() {
    _assignments = CachedData();
    notifyListeners();
  }

  // =====================
  // PENDING PROMOTIONS METHODS
  // =====================

  /// Fetch pending promotions
  Future<void> fetchPendingPromotions({bool forceRefresh = false}) async {
    const cacheKey = 'pendingPromotions';

    if (_pendingRequests[cacheKey] != null) {
      return _pendingRequests[cacheKey]!;
    }

    if (!forceRefresh && _pendingPromotions.isValid && _pendingPromotions.hasData) {
      return;
    }

    _pendingPromotions.isLoading = true;
    notifyListeners();

    _pendingRequests[cacheKey] = _fetchPendingPromotionsInternal();

    try {
      await _pendingRequests[cacheKey];
    } finally {
      _pendingRequests[cacheKey] = null;
    }
  }

  Future<void> _fetchPendingPromotionsInternal() async {
    try {
      final response = await IncentiveService.getPendingPromotions();

      if (response.success && response.data != null) {
        _pendingPromotions = CachedData(data: response.data);
      } else {
        _pendingPromotions.error = response.message;
      }
    } catch (e) {
      _pendingPromotions.error = e.toString();
    } finally {
      _pendingPromotions.isLoading = false;
      _pendingPromotions.isRefreshing = false;
      notifyListeners();
    }
  }

  /// Approve a promotion
  Future<bool> approvePromotion(String userId, {String? notes}) async {
    try {
      final response = await IncentiveService.approvePromotion(
        userId: userId,
        notes: notes,
      );

      if (response.success) {
        // Refresh pending promotions
        await fetchPendingPromotions(forceRefresh: true);
        // Also refresh assignments
        await fetchAssignments(forceRefresh: true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error approving promotion: $e');
      return false;
    }
  }

  /// Reject a promotion
  Future<bool> rejectPromotion(String userId, {required String notes}) async {
    try {
      final response = await IncentiveService.rejectPromotion(
        userId: userId,
        notes: notes,
      );

      if (response.success) {
        // Refresh pending promotions
        await fetchPendingPromotions(forceRefresh: true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error rejecting promotion: $e');
      return false;
    }
  }

  /// Clear pending promotions cache
  void clearPendingPromotions() {
    _pendingPromotions = CachedData();
    notifyListeners();
  }

  // =====================
  // UTILITY METHODS
  // =====================

  /// Clear all caches
  void clearAll() {
    _myIncentive = CachedData();
    _templates = CachedData();
    _assignments = CachedData();
    _pendingPromotions = CachedData();
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      fetchMyIncentive(forceRefresh: true),
      fetchTemplates(forceRefresh: true),
      fetchAssignments(forceRefresh: true),
      fetchPendingPromotions(forceRefresh: true),
    ]);
  }
}
