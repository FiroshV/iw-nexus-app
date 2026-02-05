import 'package:flutter/foundation.dart';
import 'incentive_template.dart';

class ProductSalesSummary {
  final int count;
  final double totalAmount;
  final double commission;

  ProductSalesSummary({
    required this.count,
    required this.totalAmount,
    required this.commission,
  });

  factory ProductSalesSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ProductSalesSummary(count: 0, totalAmount: 0, commission: 0);
    }
    return ProductSalesSummary(
      count: _parseInt(json['count']),
      totalAmount: _parseDouble(json['totalAmount']),
      commission: _parseDouble(json['commission']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

class SalesSummary {
  final ProductSalesSummary lifeInsurance;
  final ProductSalesSummary generalInsurance;
  final ProductSalesSummary mutualFunds;

  SalesSummary({
    required this.lifeInsurance,
    required this.generalInsurance,
    required this.mutualFunds,
  });

  factory SalesSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return SalesSummary(
        lifeInsurance: ProductSalesSummary(count: 0, totalAmount: 0, commission: 0),
        generalInsurance: ProductSalesSummary(count: 0, totalAmount: 0, commission: 0),
        mutualFunds: ProductSalesSummary(count: 0, totalAmount: 0, commission: 0),
      );
    }
    return SalesSummary(
      lifeInsurance: ProductSalesSummary.fromJson(json['life_insurance'] as Map<String, dynamic>?),
      generalInsurance: ProductSalesSummary.fromJson(json['general_insurance'] as Map<String, dynamic>?),
      mutualFunds: ProductSalesSummary.fromJson(json['mutual_funds'] as Map<String, dynamic>?),
    );
  }

  int get totalCount => lifeInsurance.count + generalInsurance.count + mutualFunds.count;
  double get totalAmount => lifeInsurance.totalAmount + generalInsurance.totalAmount + mutualFunds.totalAmount;
  double get totalCommission => lifeInsurance.commission + generalInsurance.commission + mutualFunds.commission;
}

class MonthlyProgress {
  final String id;
  final String month;
  final SalesSummary salesSummary;
  final double overallSalesAmount;
  final double totalCommission;
  final bool targetAchieved;
  final DateTime? targetAchievedDate;
  final List<String> salesIds;

  MonthlyProgress({
    required this.id,
    required this.month,
    required this.salesSummary,
    required this.overallSalesAmount,
    required this.totalCommission,
    required this.targetAchieved,
    this.targetAchievedDate,
    required this.salesIds,
  });

  factory MonthlyProgress.fromJson(Map<String, dynamic> json) {
    try {
      final salesSummaryData = json['salesSummary'] is Map<String, dynamic>
          ? json['salesSummary'] as Map<String, dynamic>
          : null;

      // Parse targetAchievedDate safely
      DateTime? targetAchievedDate;
      if (json['targetAchievedDate'] != null) {
        try {
          targetAchievedDate = DateTime.parse(json['targetAchievedDate'].toString());
        } catch (e) {
          debugPrint('⚠️ MonthlyProgress: Failed to parse targetAchievedDate: $e');
        }
      }

      // Parse salesIds safely
      List<String> salesIds = [];
      if (json['salesIds'] is List) {
        try {
          salesIds = (json['salesIds'] as List)
              .map((e) => e.toString())
              .toList();
        } catch (e) {
          debugPrint('⚠️ MonthlyProgress: Failed to parse salesIds: $e');
        }
      }

      return MonthlyProgress(
        id: json['_id']?.toString() ?? '',
        month: json['month']?.toString() ?? '',
        salesSummary: SalesSummary.fromJson(salesSummaryData),
        overallSalesAmount: _parseDouble(json['overallSalesAmount']),
        totalCommission: _parseDouble(json['totalCommission']),
        targetAchieved: json['targetAchieved'] ?? false,
        targetAchievedDate: targetAchievedDate,
        salesIds: salesIds,
      );
    } catch (e, stack) {
      debugPrint('❌ MonthlyProgress.fromJson: Parse error - $e');
      debugPrint('   Stack: $stack');
      rethrow;
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

class PendingPromotion {
  final bool isEligible;
  final DateTime? eligibleSince;
  final String? nextTemplateId;
  final IncentiveTemplate? nextTemplate;
  final String status; // none, pending, approved, rejected
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final String? achievementMonth;

  PendingPromotion({
    required this.isEligible,
    this.eligibleSince,
    this.nextTemplateId,
    this.nextTemplate,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNotes,
    this.achievementMonth,
  });

  factory PendingPromotion.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return PendingPromotion(isEligible: false, status: 'none');
    }

    try {
      // Handle nextTemplateId which can be a string or an object
      String? nextTemplateIdStr;
      IncentiveTemplate? nextTemplateObj;

      if (json['nextTemplateId'] != null) {
        if (json['nextTemplateId'] is String) {
          nextTemplateIdStr = json['nextTemplateId'];
        } else if (json['nextTemplateId'] is Map<String, dynamic>) {
          try {
            nextTemplateObj = IncentiveTemplate.fromJson(json['nextTemplateId'] as Map<String, dynamic>);
            nextTemplateIdStr = nextTemplateObj.id;
          } catch (e) {
            debugPrint('⚠️ PendingPromotion: Failed to parse nextTemplateId: $e');
            nextTemplateIdStr = json['nextTemplateId']?['_id']?.toString();
          }
        }
      }

      // Parse dates safely
      DateTime? eligibleSince;
      if (json['eligibleSince'] != null) {
        try {
          eligibleSince = DateTime.parse(json['eligibleSince'].toString());
        } catch (e) {
          debugPrint('⚠️ PendingPromotion: Failed to parse eligibleSince: $e');
        }
      }

      DateTime? reviewedAt;
      if (json['reviewedAt'] != null) {
        try {
          reviewedAt = DateTime.parse(json['reviewedAt'].toString());
        } catch (e) {
          debugPrint('⚠️ PendingPromotion: Failed to parse reviewedAt: $e');
        }
      }

      return PendingPromotion(
        isEligible: json['isEligible'] ?? false,
        eligibleSince: eligibleSince,
        nextTemplateId: nextTemplateIdStr,
        nextTemplate: nextTemplateObj,
        status: json['status']?.toString() ?? 'none',
        reviewedBy: json['reviewedBy']?.toString(),
        reviewedAt: reviewedAt,
        reviewNotes: json['reviewNotes']?.toString(),
        achievementMonth: json['achievementMonth']?.toString(),
      );
    } catch (e, stack) {
      debugPrint('❌ PendingPromotion.fromJson: Parse error - $e');
      debugPrint('   Stack: $stack');
      return PendingPromotion(isEligible: false, status: 'none');
    }
  }
}

class PromotionHistory {
  final String id;
  final String? fromTemplateId;
  final String fromTemplateName;
  final String toTemplateId;
  final String toTemplateName;
  final DateTime promotionDate;
  final String? approvedByName;
  final String? notes;
  final String? achievementMonth;

  PromotionHistory({
    required this.id,
    this.fromTemplateId,
    required this.fromTemplateName,
    required this.toTemplateId,
    required this.toTemplateName,
    required this.promotionDate,
    this.approvedByName,
    this.notes,
    this.achievementMonth,
  });

  factory PromotionHistory.fromJson(Map<String, dynamic> json) {
    try {
      // Handle populated template objects
      String fromName = '';
      String toName = '';
      String? fromId;
      String? toId;

      if (json['fromTemplateId'] is Map<String, dynamic>) {
        try {
          fromName = json['fromTemplateId']['name']?.toString() ?? '';
          fromId = json['fromTemplateId']['_id']?.toString();
        } catch (e) {
          debugPrint('⚠️ PromotionHistory: Failed to parse fromTemplateId: $e');
        }
      } else {
        fromId = json['fromTemplateId']?.toString();
      }

      if (json['toTemplateId'] is Map<String, dynamic>) {
        try {
          toName = json['toTemplateId']['name']?.toString() ?? '';
          toId = json['toTemplateId']['_id']?.toString() ?? '';
        } catch (e) {
          debugPrint('⚠️ PromotionHistory: Failed to parse toTemplateId: $e');
        }
      } else {
        toId = json['toTemplateId']?.toString() ?? '';
      }

      // Handle approvedBy
      String? approverName;
      if (json['approvedBy'] is Map<String, dynamic>) {
        try {
          final approver = json['approvedBy'];
          approverName = '${approver['firstName'] ?? ''} ${approver['lastName'] ?? ''}'.trim();
        } catch (e) {
          debugPrint('⚠️ PromotionHistory: Failed to parse approvedBy: $e');
        }
      }

      // Parse promotionDate safely
      DateTime promotionDate = DateTime.now();
      if (json['promotionDate'] != null) {
        try {
          promotionDate = DateTime.parse(json['promotionDate'].toString());
        } catch (e) {
          debugPrint('⚠️ PromotionHistory: Failed to parse promotionDate: $e');
        }
      }

      return PromotionHistory(
        id: json['_id']?.toString() ?? '',
        fromTemplateId: fromId,
        fromTemplateName: fromName,
        toTemplateId: toId ?? '',
        toTemplateName: toName,
        promotionDate: promotionDate,
        approvedByName: approverName,
        notes: json['notes']?.toString(),
        achievementMonth: json['achievementMonth']?.toString(),
      );
    } catch (e, stack) {
      debugPrint('❌ PromotionHistory.fromJson: Parse error - $e');
      debugPrint('   Stack: $stack');
      rethrow;
    }
  }
}

class AssignedUser {
  final String id;
  final String firstName;
  final String lastName;
  final String? employeeId;
  final String? email;
  final String? role;

  AssignedUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.employeeId,
    this.email,
    this.role,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory AssignedUser.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AssignedUser(id: '', firstName: '', lastName: '');
    }
    return AssignedUser(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      employeeId: json['employeeId'],
      email: json['email'],
      role: json['role'],
    );
  }
}

class EmployeeIncentive {
  final String id;
  final String userId;
  final AssignedUser? user;
  final String currentTemplateId;
  final IncentiveTemplate? currentTemplate;
  final List<MonthlyProgress> monthlyProgress;
  final List<PromotionHistory> promotionHistory;
  final PendingPromotion pendingPromotion;
  final String? assignedById;
  final String? assignedByName;
  final DateTime assignedAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Validity period fields
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrentlyActive;
  final String validityStatus; // 'active', 'future', 'expired', 'inactive'

  // Additional data from API
  final MonthlyProgress? currentMonthProgress;
  final IncentiveTemplate? nextTemplate;

  EmployeeIncentive({
    required this.id,
    required this.userId,
    this.user,
    required this.currentTemplateId,
    this.currentTemplate,
    required this.monthlyProgress,
    required this.promotionHistory,
    required this.pendingPromotion,
    this.assignedById,
    this.assignedByName,
    required this.assignedAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.startDate,
    this.endDate,
    this.isCurrentlyActive = true,
    this.validityStatus = 'active',
    this.currentMonthProgress,
    this.nextTemplate,
  });

  /// Get validity period as a display string
  String get validityPeriodString {
    if (startDate == null) return 'Not set';
    final startStr = '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}';
    final endStr = endDate != null
        ? '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}'
        : 'Present';
    return '$startStr - $endStr';
  }

  /// Check if the validity period is ongoing (no end date)
  bool get isOngoing => endDate == null;

  // =====================
  // SAFE PARSING HELPERS
  // =====================

  static DateTime? _safeParseDateTime(dynamic value, String fieldName) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      debugPrint('⚠️ EmployeeIncentive: Failed to parse DateTime for $fieldName: $e');
      debugPrint('   Value: $value (type: ${value.runtimeType})');
      return null;
    }
  }

  static List<T> _safeParseList<T>(
    dynamic value,
    T Function(Map<String, dynamic>) parser,
    String fieldName,
  ) {
    if (value == null) return [];

    if (value is! List) {
      debugPrint('⚠️ EmployeeIncentive: $fieldName is not a List, got ${value.runtimeType}');
      return [];
    }

    final List<T> result = [];
    final list = value;

    for (int i = 0; i < list.length; i++) {
      try {
        if (list[i] is Map<String, dynamic>) {
          result.add(parser(list[i] as Map<String, dynamic>));
        } else {
          debugPrint('⚠️ EmployeeIncentive: $fieldName[$i] is not a Map, got ${list[i].runtimeType}');
        }
      } catch (e, stack) {
        debugPrint('⚠️ EmployeeIncentive: Failed to parse $fieldName[$i]: $e');
        debugPrint('   Stack: $stack');
      }
    }

    return result;
  }

  static Map<String, dynamic>? _safeParseMap(dynamic value, String fieldName) {
    if (value == null) return null;

    if (value is Map<String, dynamic>) {
      return value;
    }

    debugPrint('⚠️ EmployeeIncentive: $fieldName is not a Map<String, dynamic>, got ${value.runtimeType}');
    return null;
  }

  factory EmployeeIncentive.fromJson(Map<String, dynamic> json) {
    debugPrint('📦 EmployeeIncentive.fromJson: Starting parse...');

    try {
      // Handle userId which can be a string or an object
      String userIdStr;
      AssignedUser? userObj;

      if (json['userId'] is String) {
        userIdStr = json['userId'];
      } else if (json['userId'] is Map<String, dynamic>) {
        try {
          userObj = AssignedUser.fromJson(json['userId'] as Map<String, dynamic>);
          userIdStr = userObj.id;
        } catch (e) {
          debugPrint('⚠️ EmployeeIncentive: Failed to parse userId object: $e');
          userIdStr = json['userId']?['_id']?.toString() ?? '';
        }
      } else {
        debugPrint('⚠️ EmployeeIncentive: Unexpected userId type: ${json['userId'].runtimeType}');
        userIdStr = json['userId']?.toString() ?? '';
      }

      // Handle currentTemplateId (string ID) and currentTemplate (populated object)
      String templateIdStr = '';
      IncentiveTemplate? templateObj;

      // First, get the string ID
      if (json['currentTemplateId'] is String) {
        templateIdStr = json['currentTemplateId'];
      } else if (json['currentTemplateId'] is Map<String, dynamic>) {
        // Backwards compatibility: if currentTemplateId is a populated object
        templateIdStr = json['currentTemplateId']?['_id']?.toString() ?? '';
      }

      // Then, parse currentTemplate if available (preferred)
      if (json['currentTemplate'] is Map<String, dynamic>) {
        try {
          templateObj = IncentiveTemplate.fromJson(json['currentTemplate'] as Map<String, dynamic>);
          if (templateIdStr.isEmpty) {
            templateIdStr = templateObj.id;
          }
        } catch (e) {
          debugPrint('⚠️ EmployeeIncentive: Failed to parse currentTemplate object: $e');
        }
      }

      // Handle assignedBy
      String? assignedById;
      String? assignedByName;
      if (json['assignedBy'] is Map<String, dynamic>) {
        try {
          final assigner = json['assignedBy'];
          assignedById = assigner['_id'];
          assignedByName = '${assigner['firstName'] ?? ''} ${assigner['lastName'] ?? ''}'.trim();
        } catch (e) {
          debugPrint('⚠️ EmployeeIncentive: Failed to parse assignedBy: $e');
        }
      } else {
        assignedById = json['assignedBy']?.toString();
      }

      // Handle nextTemplate - SAFE PARSING
      IncentiveTemplate? nextTemplate;
      final nextTemplateData = _safeParseMap(json['nextTemplate'], 'nextTemplate');
      if (nextTemplateData != null) {
        try {
          nextTemplate = IncentiveTemplate.fromJson(nextTemplateData);
        } catch (e) {
          debugPrint('⚠️ EmployeeIncentive: Failed to parse nextTemplate: $e');
        }
      }

      // Handle currentMonthProgress - SAFE PARSING
      MonthlyProgress? currentMonthProgress;
      final currentMonthData = _safeParseMap(json['currentMonthProgress'], 'currentMonthProgress');
      if (currentMonthData != null) {
        try {
          currentMonthProgress = MonthlyProgress.fromJson(currentMonthData);
        } catch (e) {
          debugPrint('⚠️ EmployeeIncentive: Failed to parse currentMonthProgress: $e');
        }
      }

      // Parse monthlyProgress with SAFE LIST PARSING
      final monthlyProgressList = _safeParseList<MonthlyProgress>(
        json['monthlyProgress'],
        MonthlyProgress.fromJson,
        'monthlyProgress',
      );

      // Parse promotionHistory with SAFE LIST PARSING
      final promotionHistoryList = _safeParseList<PromotionHistory>(
        json['promotionHistory'],
        PromotionHistory.fromJson,
        'promotionHistory',
      );

      // Parse pendingPromotion - SAFE PARSING
      final pendingPromotionData = _safeParseMap(json['pendingPromotion'], 'pendingPromotion');
      final pendingPromotion = PendingPromotion.fromJson(pendingPromotionData);

      // Parse dates safely
      final assignedAt = _safeParseDateTime(json['assignedAt'], 'assignedAt') ?? DateTime.now();
      final createdAt = _safeParseDateTime(json['createdAt'], 'createdAt') ?? DateTime.now();
      final updatedAt = _safeParseDateTime(json['updatedAt'], 'updatedAt') ?? DateTime.now();

      // Parse validity period dates
      final startDate = _safeParseDateTime(json['startDate'], 'startDate');
      final endDate = _safeParseDateTime(json['endDate'], 'endDate');
      final isCurrentlyActive = json['isCurrentlyActive'] ?? true;
      final validityStatus = json['validityStatus']?.toString() ?? 'active';

      debugPrint('✅ EmployeeIncentive.fromJson: Parse successful');

      return EmployeeIncentive(
        id: json['_id']?.toString() ?? '',
        userId: userIdStr,
        user: userObj,
        currentTemplateId: templateIdStr,
        currentTemplate: templateObj,
        monthlyProgress: monthlyProgressList,
        promotionHistory: promotionHistoryList,
        pendingPromotion: pendingPromotion,
        assignedById: assignedById,
        assignedByName: assignedByName,
        assignedAt: assignedAt,
        isActive: json['isActive'] ?? true,
        createdAt: createdAt,
        updatedAt: updatedAt,
        startDate: startDate,
        endDate: endDate,
        isCurrentlyActive: isCurrentlyActive,
        validityStatus: validityStatus,
        currentMonthProgress: currentMonthProgress,
        nextTemplate: nextTemplate,
      );
    } catch (e, stack) {
      debugPrint('❌ EmployeeIncentive.fromJson: CRITICAL PARSING ERROR');
      debugPrint('   Error: $e');
      debugPrint('   Stack: $stack');
      debugPrint('   JSON keys: ${json.keys.toList()}');
      rethrow;
    }
  }

  /// Get the progress for a specific month
  MonthlyProgress? getProgressForMonth(String month) {
    try {
      return monthlyProgress.firstWhere((p) => p.month == month);
    } catch (e) {
      return null;
    }
  }

  /// Get current month string in YYYY-MM format
  static String get currentMonthString {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Create a copy of this incentive with modified fields
  EmployeeIncentive copyWith({
    String? id,
    String? userId,
    AssignedUser? user,
    String? currentTemplateId,
    IncentiveTemplate? currentTemplate,
    List<MonthlyProgress>? monthlyProgress,
    List<PromotionHistory>? promotionHistory,
    PendingPromotion? pendingPromotion,
    String? assignedById,
    String? assignedByName,
    DateTime? assignedAt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrentlyActive,
    String? validityStatus,
    MonthlyProgress? currentMonthProgress,
    IncentiveTemplate? nextTemplate,
  }) {
    return EmployeeIncentive(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      currentTemplateId: currentTemplateId ?? this.currentTemplateId,
      currentTemplate: currentTemplate ?? this.currentTemplate,
      monthlyProgress: monthlyProgress ?? this.monthlyProgress,
      promotionHistory: promotionHistory ?? this.promotionHistory,
      pendingPromotion: pendingPromotion ?? this.pendingPromotion,
      assignedById: assignedById ?? this.assignedById,
      assignedByName: assignedByName ?? this.assignedByName,
      assignedAt: assignedAt ?? this.assignedAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrentlyActive: isCurrentlyActive ?? this.isCurrentlyActive,
      validityStatus: validityStatus ?? this.validityStatus,
      currentMonthProgress: currentMonthProgress ?? this.currentMonthProgress,
      nextTemplate: nextTemplate ?? this.nextTemplate,
    );
  }
}

/// Target progress information for display
class TargetProgress {
  final String type; // overall_amount, product_wise, combined
  final double? overallTarget;
  final double? overallAchieved;
  final double? overallPercentage;
  final Map<String, ProductProgress>? products;
  final bool isComplete;

  TargetProgress({
    required this.type,
    this.overallTarget,
    this.overallAchieved,
    this.overallPercentage,
    this.products,
    required this.isComplete,
  });

  factory TargetProgress.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return TargetProgress(type: 'overall_amount', isComplete: false);
    }

    Map<String, ProductProgress>? products;
    if (json['products'] != null && json['products'] is Map<String, dynamic>) {
      products = {};
      (json['products'] as Map<String, dynamic>).forEach((key, value) {
        if (value is Map<String, dynamic>) {
          products![key] = ProductProgress.fromJson(value);
        }
      });
    }

    return TargetProgress(
      type: json['type'] ?? 'overall_amount',
      overallTarget: _parseDouble(json['target'] ?? json['overallTarget']),
      overallAchieved: _parseDouble(json['achieved'] ?? json['overallAchieved']),
      overallPercentage: _parseDouble(json['percentage'] ?? json['overallPercentage']),
      products: products,
      isComplete: json['isComplete'] ?? false,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class ProductProgress {
  final int countTarget;
  final int countAchieved;
  final double countPercentage;
  final double amountTarget;
  final double amountAchieved;
  final double amountPercentage;

  ProductProgress({
    required this.countTarget,
    required this.countAchieved,
    required this.countPercentage,
    required this.amountTarget,
    required this.amountAchieved,
    required this.amountPercentage,
  });

  factory ProductProgress.fromJson(Map<String, dynamic> json) {
    return ProductProgress(
      countTarget: _parseInt(json['countTarget']),
      countAchieved: _parseInt(json['countAchieved']),
      countPercentage: _parseDouble(json['countPercentage']),
      amountTarget: _parseDouble(json['amountTarget']),
      amountAchieved: _parseDouble(json['amountAchieved']),
      amountPercentage: _parseDouble(json['amountPercentage']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
