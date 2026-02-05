import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/product_service.dart';

enum ProductLoadingState {
  initial,
  loading,
  loaded,
  error,
}

class ProductProvider extends ChangeNotifier {
  // State
  ProductLoadingState _loadingState = ProductLoadingState.initial;
  List<Product> _products = [];
  GroupedProducts? _groupedProducts;
  List<String> _companyNames = [];
  String? _errorMessage;
  int _total = 0;
  int _page = 1;
  int _totalPages = 1;

  // Filters
  String? _selectedCategory;
  String? _selectedCompany;
  String? _searchQuery;
  bool? _filterActive;

  // Getters
  ProductLoadingState get loadingState => _loadingState;
  List<Product> get products => _products;
  GroupedProducts? get groupedProducts => _groupedProducts;
  List<String> get companyNames => _companyNames;
  String? get errorMessage => _errorMessage;
  int get total => _total;
  int get page => _page;
  int get totalPages => _totalPages;
  String? get selectedCategory => _selectedCategory;
  String? get selectedCompany => _selectedCompany;
  String? get searchQuery => _searchQuery;
  bool? get filterActive => _filterActive;

  bool get isLoading => _loadingState == ProductLoadingState.loading;
  bool get hasError => _loadingState == ProductLoadingState.error;
  bool get isEmpty => _products.isEmpty && _loadingState == ProductLoadingState.loaded;

  // Filter products by category locally
  List<Product> getProductsByCategory(ProductCategory category) {
    return _products.where((p) => p.category == category).toList();
  }

  // Set filters
  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setCompany(String? company) {
    _selectedCompany = company;
    notifyListeners();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterActive(bool? active) {
    _filterActive = active;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedCompany = null;
    _searchQuery = null;
    _filterActive = null;
    notifyListeners();
  }

  // Fetch products
  Future<void> fetchProducts({
    int skip = 0,
    int limit = 50,
    bool refresh = false,
  }) async {
    if (refresh) {
      _products = [];
    }

    _loadingState = ProductLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    final response = await ProductService.getProducts(
      skip: skip,
      limit: limit,
      category: _selectedCategory,
      companyName: _selectedCompany,
      search: _searchQuery,
      isActive: _filterActive,
    );

    if (response.success && response.data != null) {
      _products = response.data!;
      _total = response.total ?? _products.length;
      _page = response.page ?? 1;
      _totalPages = response.totalPages ?? 1;
      _loadingState = ProductLoadingState.loaded;
    } else {
      _errorMessage = response.message ?? 'Failed to fetch products';
      _loadingState = ProductLoadingState.error;
    }

    notifyListeners();
  }

  // Fetch grouped products
  Future<void> fetchGroupedProducts() async {
    _loadingState = ProductLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    final response = await ProductService.getGroupedProducts();

    if (response.success && response.data != null) {
      _groupedProducts = response.data!;
      _products = _groupedProducts!.allProducts;
      _total = _groupedProducts!.totalCount;
      _loadingState = ProductLoadingState.loaded;
    } else {
      _errorMessage = response.message ?? 'Failed to fetch products';
      _loadingState = ProductLoadingState.error;
    }

    notifyListeners();
  }

  // Fetch products by category
  Future<void> fetchProductsByCategory(String category, {bool activeOnly = true}) async {
    _loadingState = ProductLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    final response = await ProductService.getProductsByCategory(
      category,
      activeOnly: activeOnly,
    );

    if (response.success && response.data != null) {
      _products = response.data!;
      _total = response.total ?? _products.length;
      _loadingState = ProductLoadingState.loaded;
    } else {
      _errorMessage = response.message ?? 'Failed to fetch products';
      _loadingState = ProductLoadingState.error;
    }

    notifyListeners();
  }

  // Fetch company names
  Future<void> fetchCompanyNames({String? category}) async {
    final response = await ProductService.getCompanyNames(category: category);

    if (response.success && response.data != null) {
      _companyNames = response.data!;
      notifyListeners();
    }
  }

  // Create product
  Future<ProductApiResponse<Product>> createProduct({
    required String name,
    required String category,
    required String companyName,
    String? description,
    required double commissionRate,
  }) async {
    final response = await ProductService.createProduct(
      name: name,
      category: category,
      companyName: companyName,
      description: description,
      commissionRate: commissionRate,
    );

    if (response.success && response.data != null) {
      _products.insert(0, response.data!);
      _total++;
      notifyListeners();
    }

    return response;
  }

  // Update product
  Future<ProductApiResponse<Product>> updateProduct({
    required String productId,
    required String name,
    required String category,
    required String companyName,
    String? description,
    required double commissionRate,
    bool? isActive,
  }) async {
    final response = await ProductService.updateProduct(
      productId: productId,
      name: name,
      category: category,
      companyName: companyName,
      description: description,
      commissionRate: commissionRate,
      isActive: isActive,
    );

    if (response.success && response.data != null) {
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = response.data!;
        notifyListeners();
      }
    }

    return response;
  }

  // Delete product
  Future<ProductApiResponse<void>> deleteProduct(String productId) async {
    final response = await ProductService.deleteProduct(productId);

    if (response.success) {
      _products.removeWhere((p) => p.id == productId);
      _total--;
      notifyListeners();
    }

    return response;
  }

  // Toggle product active status
  Future<ProductApiResponse<Map<String, dynamic>>> toggleProductActive(String productId) async {
    final response = await ProductService.toggleProductActive(productId);

    if (response.success && response.data != null) {
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final newActiveState = response.data!['isActive'] as bool? ?? !_products[index].isActive;
        _products[index] = _products[index].copyWith(isActive: newActiveState);
        notifyListeners();
      }
    }

    return response;
  }

  // Get product by ID from cached list
  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Refresh products
  Future<void> refresh() async {
    await fetchProducts(refresh: true);
  }

  // Reset state
  void reset() {
    _loadingState = ProductLoadingState.initial;
    _products = [];
    _groupedProducts = null;
    _companyNames = [];
    _errorMessage = null;
    _total = 0;
    _page = 1;
    _totalPages = 1;
    _selectedCategory = null;
    _selectedCompany = null;
    _searchQuery = null;
    _filterActive = null;
    notifyListeners();
  }
}
