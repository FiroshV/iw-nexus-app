class CommissionRates {
  final double lifeInsurance;
  final double generalInsurance;
  final double mutualFunds;

  CommissionRates({
    required this.lifeInsurance,
    required this.generalInsurance,
    required this.mutualFunds,
  });

  factory CommissionRates.fromJson(Map<String, dynamic> json) {
    return CommissionRates(
      lifeInsurance: _parseDouble(json['life_insurance']),
      generalInsurance: _parseDouble(json['general_insurance']),
      mutualFunds: _parseDouble(json['mutual_funds']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'life_insurance': lifeInsurance,
      'general_insurance': generalInsurance,
      'mutual_funds': mutualFunds,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

class OverallTarget {
  final double amount;

  OverallTarget({required this.amount});

  factory OverallTarget.fromJson(Map<String, dynamic>? json) {
    if (json == null) return OverallTarget(amount: 0);
    return OverallTarget(
      amount: _parseDouble(json['amount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'amount': amount};
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

class ProductTarget {
  final int count;
  final double amount;

  ProductTarget({
    required this.count,
    required this.amount,
  });

  factory ProductTarget.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ProductTarget(count: 0, amount: 0);
    return ProductTarget(
      count: _parseInt(json['count']),
      amount: _parseDouble(json['amount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'amount': amount,
    };
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

class ProductTargets {
  final ProductTarget lifeInsurance;
  final ProductTarget generalInsurance;
  final ProductTarget mutualFunds;

  ProductTargets({
    required this.lifeInsurance,
    required this.generalInsurance,
    required this.mutualFunds,
  });

  factory ProductTargets.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ProductTargets(
        lifeInsurance: ProductTarget(count: 0, amount: 0),
        generalInsurance: ProductTarget(count: 0, amount: 0),
        mutualFunds: ProductTarget(count: 0, amount: 0),
      );
    }
    return ProductTargets(
      lifeInsurance: ProductTarget.fromJson(json['life_insurance'] as Map<String, dynamic>?),
      generalInsurance: ProductTarget.fromJson(json['general_insurance'] as Map<String, dynamic>?),
      mutualFunds: ProductTarget.fromJson(json['mutual_funds'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'life_insurance': lifeInsurance.toJson(),
      'general_insurance': generalInsurance.toJson(),
      'mutual_funds': mutualFunds.toJson(),
    };
  }
}

class CreatedByUser {
  final String id;
  final String firstName;
  final String lastName;
  final String? employeeId;

  CreatedByUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.employeeId,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory CreatedByUser.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CreatedByUser(id: '', firstName: '', lastName: '');
    }
    return CreatedByUser(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      employeeId: json['employeeId'],
    );
  }
}

class NextTemplateInfo {
  final String id;
  final String name;
  final String templateId;
  final CommissionRates? commissionRates;

  NextTemplateInfo({
    required this.id,
    required this.name,
    required this.templateId,
    this.commissionRates,
  });

  factory NextTemplateInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return NextTemplateInfo(id: '', name: '', templateId: '');
    }
    return NextTemplateInfo(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      templateId: json['templateId'] ?? '',
      commissionRates: json['commissionRates'] != null
          ? CommissionRates.fromJson(json['commissionRates'] as Map<String, dynamic>)
          : null,
    );
  }
}

class IncentiveTemplate {
  final String id;
  final String templateId;
  final String name;
  final String? description;
  final CommissionRates commissionRates;
  final String targetType; // overall_amount, product_wise, combined
  final OverallTarget overallTarget;
  final ProductTargets productTargets;
  final String? nextTemplateId;
  final NextTemplateInfo? nextTemplate;
  final CreatedByUser? createdBy;
  final int? employeeCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  IncentiveTemplate({
    required this.id,
    required this.templateId,
    required this.name,
    this.description,
    required this.commissionRates,
    required this.targetType,
    required this.overallTarget,
    required this.productTargets,
    this.nextTemplateId,
    this.nextTemplate,
    this.createdBy,
    this.employeeCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IncentiveTemplate.fromJson(Map<String, dynamic> json) {
    // Handle nextTemplateId which can be a string or an object
    String? nextTemplateIdStr;
    NextTemplateInfo? nextTemplateInfo;

    if (json['nextTemplateId'] != null) {
      if (json['nextTemplateId'] is String) {
        nextTemplateIdStr = json['nextTemplateId'];
      } else if (json['nextTemplateId'] is Map<String, dynamic>) {
        nextTemplateInfo = NextTemplateInfo.fromJson(json['nextTemplateId']);
        nextTemplateIdStr = nextTemplateInfo.id;
      }
    }

    // Safe parsing for commissionRates
    CommissionRates commissionRates;
    if (json['commissionRates'] is Map<String, dynamic>) {
      commissionRates = CommissionRates.fromJson(json['commissionRates']);
    } else {
      commissionRates = CommissionRates(lifeInsurance: 0, generalInsurance: 0, mutualFunds: 0);
    }

    // Safe parsing for overallTarget
    OverallTarget overallTarget;
    if (json['overallTarget'] is Map<String, dynamic>) {
      overallTarget = OverallTarget.fromJson(json['overallTarget']);
    } else {
      overallTarget = OverallTarget(amount: 0);
    }

    // Safe parsing for productTargets
    ProductTargets productTargets;
    if (json['productTargets'] is Map<String, dynamic>) {
      productTargets = ProductTargets.fromJson(json['productTargets']);
    } else {
      productTargets = ProductTargets(
        lifeInsurance: ProductTarget(count: 0, amount: 0),
        generalInsurance: ProductTarget(count: 0, amount: 0),
        mutualFunds: ProductTarget(count: 0, amount: 0),
      );
    }

    // Safe parsing for createdBy
    CreatedByUser? createdBy;
    if (json['createdBy'] is Map<String, dynamic>) {
      createdBy = CreatedByUser.fromJson(json['createdBy']);
    }

    // Safe parsing for dates
    DateTime createdAt;
    try {
      createdAt = json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now();
    } catch (_) {
      createdAt = DateTime.now();
    }

    DateTime updatedAt;
    try {
      updatedAt = json['updatedAt'] != null ? DateTime.parse(json['updatedAt'].toString()) : DateTime.now();
    } catch (_) {
      updatedAt = DateTime.now();
    }

    return IncentiveTemplate(
      id: json['_id']?.toString() ?? '',
      templateId: json['templateId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      commissionRates: commissionRates,
      targetType: json['targetType']?.toString() ?? 'overall_amount',
      overallTarget: overallTarget,
      productTargets: productTargets,
      nextTemplateId: nextTemplateIdStr,
      nextTemplate: nextTemplateInfo,
      createdBy: createdBy,
      employeeCount: json['employeeCount'] is int ? json['employeeCount'] : null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'commissionRates': commissionRates.toJson(),
      'targetType': targetType,
      'overallTarget': overallTarget.toJson(),
      'productTargets': productTargets.toJson(),
      'nextTemplateId': nextTemplateId,
    };
  }

  /// Get a human-readable target description
  String get targetDescription {
    if (targetType == 'overall_amount') {
      return 'Overall Sales: ${_formatAmount(overallTarget.amount)}';
    } else if (targetType == 'product_wise') {
      List<String> parts = [];
      if (productTargets.lifeInsurance.count > 0 || productTargets.lifeInsurance.amount > 0) {
        parts.add('Life: ${productTargets.lifeInsurance.count > 0 ? '${productTargets.lifeInsurance.count} sales' : _formatAmount(productTargets.lifeInsurance.amount)}');
      }
      if (productTargets.generalInsurance.count > 0 || productTargets.generalInsurance.amount > 0) {
        parts.add('General: ${productTargets.generalInsurance.count > 0 ? '${productTargets.generalInsurance.count} sales' : _formatAmount(productTargets.generalInsurance.amount)}');
      }
      if (productTargets.mutualFunds.count > 0 || productTargets.mutualFunds.amount > 0) {
        parts.add('MF: ${productTargets.mutualFunds.count > 0 ? '${productTargets.mutualFunds.count} sales' : _formatAmount(productTargets.mutualFunds.amount)}');
      }
      return parts.join(' | ');
    } else {
      return 'Combined: ${_formatAmount(overallTarget.amount)} + product targets';
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
