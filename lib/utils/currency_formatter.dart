import 'package:intl/intl.dart';

/// Currency formatter supporting multiple currencies
class CurrencyFormatter {
  /// Format a number as currency based on currency code
  static String format(double amount, String currencyCode) {
    final formatter = NumberFormat.currency(
      symbol: _getSymbol(currencyCode),
      decimalDigits: _getDecimalDigits(currencyCode),
    );
    return formatter.format(amount);
  }

  /// Format as compact (e.g., $1.2M, €500K)
  static String formatCompact(double amount, String currencyCode) {
    final symbol = _getSymbol(currencyCode);

    if (amount.abs() >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return format(amount, currencyCode);
    }
  }

  /// Get currency symbol
  static String _getSymbol(String currencyCode) {
    switch (currencyCode) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'INR':
        return '₹';
      case 'THB':
        return '฿';
      default:
        return '\$'; // Default to USD
    }
  }

  /// Get decimal digits for currency
  static int _getDecimalDigits(String currencyCode) {
    switch (currencyCode) {
      case 'INR':
      case 'THB':
        return 0; // These currencies typically don't show decimals
      default:
        return 2; // USD, EUR default to 2 decimals
    }
  }

  /// Get currency name
  static String getCurrencyName(String currencyCode) {
    switch (currencyCode) {
      case 'USD':
        return 'US Dollar';
      case 'EUR':
        return 'Euro';
      case 'INR':
        return 'Indian Rupee';
      case 'THB':
        return 'Thai Baht';
      default:
        return 'US Dollar';
    }
  }

  /// List of supported currencies
  static const List<String> supportedCurrencies = ['USD', 'EUR', 'INR', 'THB'];
}
