/// Currency formatting utility for gamification
///
/// Formats amounts in Indian currency notation:
/// - ₹10Cr for crores (10 million+)
/// - ₹5.2L for lakhs (100 thousand+)
/// - ₹8.5K for thousands (1 thousand+)
/// - ₹500 for smaller amounts
class CurrencyFormatter {
  /// Format amount in Indian currency notation
  ///
  /// Examples:
  /// - 15000000 → ₹1.5Cr
  /// - 250000 → ₹2.5L
  /// - 5000 → ₹5K
  /// - 500 → ₹500
  static String format(double amount) {
    if (amount >= 10000000) {
      // Crores (10 million+)
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      // Lakhs (100 thousand+)
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      // Thousands
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    // Smaller amounts
    return '₹${amount.toStringAsFixed(0)}';
  }
}
