import 'package:flutter/foundation.dart';

/// Product categories
enum ProductCategory {
  lifeInsurance('life_insurance', 'Life Insurance'),
  generalInsurance('general_insurance', 'General Insurance'),
  mutualFunds('mutual_funds', 'Mutual Funds');

  const ProductCategory(this.value, this.displayName);
  final String value;
  final String displayName;

  static ProductCategory fromString(String? value) {
    switch (value) {
      case 'life_insurance':
        return ProductCategory.lifeInsurance;
      case 'general_insurance':
        return ProductCategory.generalInsurance;
      case 'mutual_funds':
        return ProductCategory.mutualFunds;
      default:
        return ProductCategory.lifeInsurance;
    }
  }
}

/// Product model representing insurance/mutual fund products
class Product {
  final String id;
  final String productId;
  final String name;
  final ProductCategory category;
  final String companyName;
  final String? description;
  final double commissionRate;
  final bool isActive;
  final String? createdById;
  final String? createdByName;
  final String? updatedById;
  final String? updatedByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.productId,
    required this.name,
    required this.category,
    required this.companyName,
    this.description,
    required this.commissionRate,
    required this.isActive,
    this.createdById,
    this.createdByName,
    this.updatedById,
    this.updatedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  String get categoryDisplay => category.displayName;

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      // Parse createdBy
      String? createdById;
      String? createdByName;
      if (json['createdBy'] is Map<String, dynamic>) {
        final createdBy = json['createdBy'] as Map<String, dynamic>;
        createdById = createdBy['_id']?.toString();
        createdByName = '${createdBy['firstName'] ?? ''} ${createdBy['lastName'] ?? ''}'.trim();
      } else {
        createdById = json['createdBy']?.toString();
      }

      // Parse updatedBy
      String? updatedById;
      String? updatedByName;
      if (json['updatedBy'] is Map<String, dynamic>) {
        final updatedBy = json['updatedBy'] as Map<String, dynamic>;
        updatedById = updatedBy['_id']?.toString();
        updatedByName = '${updatedBy['firstName'] ?? ''} ${updatedBy['lastName'] ?? ''}'.trim();
      } else {
        updatedById = json['updatedBy']?.toString();
      }

      return Product(
        id: json['_id']?.toString() ?? '',
        productId: json['productId']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        category: ProductCategory.fromString(json['category']?.toString()),
        companyName: json['companyName']?.toString() ?? '',
        description: json['description']?.toString(),
        commissionRate: _parseDouble(json['commissionRate']),
        isActive: json['isActive'] ?? true,
        createdById: createdById,
        createdByName: createdByName,
        updatedById: updatedById,
        updatedByName: updatedByName,
        createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
      );
    } catch (e, stack) {
      debugPrint('Product.fromJson error: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category.value,
      'companyName': companyName,
      'description': description,
      'commissionRate': commissionRate,
      'isActive': isActive,
    };
  }

  Product copyWith({
    String? id,
    String? productId,
    String? name,
    ProductCategory? category,
    String? companyName,
    String? description,
    double? commissionRate,
    bool? isActive,
    String? createdById,
    String? createdByName,
    String? updatedById,
    String? updatedByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      category: category ?? this.category,
      companyName: companyName ?? this.companyName,
      description: description ?? this.description,
      commissionRate: commissionRate ?? this.commissionRate,
      isActive: isActive ?? this.isActive,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      updatedById: updatedById ?? this.updatedById,
      updatedByName: updatedByName ?? this.updatedByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    return 'Product{id: $id, productId: $productId, name: $name, category: ${category.value}, company: $companyName, commissionRate: $commissionRate}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Grouped products by category
class GroupedProducts {
  final List<Product> lifeInsurance;
  final List<Product> generalInsurance;
  final List<Product> mutualFunds;

  GroupedProducts({
    required this.lifeInsurance,
    required this.generalInsurance,
    required this.mutualFunds,
  });

  factory GroupedProducts.fromJson(Map<String, dynamic> json) {
    return GroupedProducts(
      lifeInsurance: _parseProductList(json['life_insurance']),
      generalInsurance: _parseProductList(json['general_insurance']),
      mutualFunds: _parseProductList(json['mutual_funds']),
    );
  }

  static List<Product> _parseProductList(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];
    return value
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  List<Product> get allProducts => [...lifeInsurance, ...generalInsurance, ...mutualFunds];

  int get totalCount => lifeInsurance.length + generalInsurance.length + mutualFunds.length;
}
