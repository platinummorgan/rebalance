import 'package:intl/intl.dart';
import 'package:currency_picker/currency_picker.dart';
import '../services/exchange_rate_service.dart';

/// Currency formatter supporting multiple currencies with currency_picker integration
class CurrencyFormatter {
  /// Format a number as currency based on currency code (no conversion)
  static String format(double amount, String currencyCode) {
    final formatter = NumberFormat.currency(
      symbol: _getSymbol(currencyCode),
      decimalDigits: _getDecimalDigits(currencyCode),
    );
    return formatter.format(amount);
  }

  /// Format with currency conversion from base currency to display currency
  /// [amount] - Amount in base currency (typically USD)
  /// [baseCurrency] - Currency code of the amount (e.g., 'USD')
  /// [displayCurrency] - Target currency code to display (e.g., 'EUR')
  /// [exchangeRateService] - Service to fetch exchange rates
  static Future<String> formatWithConversion(
    double amount,
    String baseCurrency,
    String displayCurrency,
    ExchangeRateService exchangeRateService,
  ) async {
    // If same currency, no conversion needed
    if (baseCurrency == displayCurrency) {
      return format(amount, displayCurrency);
    }

    // Convert the amount
    final convertedAmount = await exchangeRateService.convert(
      amount,
      baseCurrency,
      displayCurrency,
    );

    // Format with appropriate symbol and decimals
    final formatter = NumberFormat.currency(
      symbol: _getSymbol(displayCurrency),
      decimalDigits: _getDecimalDigits(displayCurrency),
    );
    return formatter.format(convertedAmount);
  }

  /// Format compact with currency conversion (e.g., $1.2M → €1.1M)
  /// [amount] - Amount in base currency
  /// [baseCurrency] - Currency code of the amount
  /// [displayCurrency] - Target currency code to display
  /// [exchangeRateService] - Service to fetch exchange rates
  static Future<String> formatCompactWithConversion(
    double amount,
    String baseCurrency,
    String displayCurrency,
    ExchangeRateService exchangeRateService,
  ) async {
    // If same currency, no conversion needed
    if (baseCurrency == displayCurrency) {
      return formatCompact(amount, displayCurrency);
    }

    // Convert the amount
    final convertedAmount = await exchangeRateService.convert(
      amount,
      baseCurrency,
      displayCurrency,
    );

    // Format compact with appropriate symbol
    final symbol = _getSymbol(displayCurrency);

    if (convertedAmount.abs() >= 1000000) {
      return '$symbol${(convertedAmount / 1000000).toStringAsFixed(1)}M';
    } else if (convertedAmount.abs() >= 1000) {
      return '$symbol${(convertedAmount / 1000).toStringAsFixed(1)}K';
    } else {
      return format(convertedAmount, displayCurrency);
    }
  }

  /// Format using Currency object from currency_picker
  static String formatWithCurrency(double amount, Currency currency) {
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: _getDecimalDigitsForCurrency(currency),
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

  /// Get a NumberFormat.currency configured for the specified currency
  /// This is useful for migrating existing code that uses NumberFormat
  static NumberFormat getFormatter(String currencyCode, {int? decimalDigits}) {
    return NumberFormat.currency(
      symbol: _getSymbol(currencyCode),
      decimalDigits: decimalDigits ?? _getDecimalDigits(currencyCode),
    );
  }

  /// Get currency symbol
  static String _getSymbol(String currencyCode) {
    try {
      final currency = CurrencyService().findByCode(currencyCode);
      if (currency != null) {
        return currency.symbol;
      }
    } catch (e) {
      // Fall through to hardcoded fallback
    }

    // Fallback for common currencies if currency_picker fails
    switch (currencyCode) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'INR':
        return '₹';
      case 'THB':
        return '฿';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CNY':
        return '¥';
      default:
        return '\$'; // Default to USD
    }
  }

  /// Get decimal digits for currency
  static int _getDecimalDigits(String currencyCode) {
    try {
      final currency = CurrencyService().findByCode(currencyCode);
      if (currency != null) {
        return _getDecimalDigitsForCurrency(currency);
      }
    } catch (e) {
      // Fall through to hardcoded fallback
    }

    // Fallback for common currencies if currency_picker fails
    switch (currencyCode) {
      case 'INR':
      case 'THB':
      case 'JPY': // Japanese Yen
      case 'KRW': // Korean Won
      case 'VND': // Vietnamese Dong
        return 0; // These currencies typically don't show decimals
      default:
        return 2; // Most currencies default to 2 decimals
    }
  }

  /// Get decimal digits from Currency object
  static int _getDecimalDigitsForCurrency(Currency currency) {
    // JPY, KRW, VND and similar currencies don't use decimals
    if (currency.code == 'JPY' ||
        currency.code == 'KRW' ||
        currency.code == 'VND' ||
        currency.code == 'IDR' ||
        currency.code == 'CLP' ||
        currency.code == 'PYG') {
      return 0;
    }

    // BHD, KWD, OMR use 3 decimals
    if (currency.code == 'BHD' ||
        currency.code == 'KWD' ||
        currency.code == 'OMR') {
      return 3;
    }

    return 2; // Default for most currencies
  }

  /// Get currency name
  static String getCurrencyName(String currencyCode) {
    try {
      final currency = CurrencyService().findByCode(currencyCode);
      return currency?.name ?? 'US Dollar';
    } catch (e) {
      // Fallback if currency not found
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
  }

  /// Get Currency object from currency_picker
  static Currency? getCurrency(String currencyCode) {
    return CurrencyService().findByCode(currencyCode);
  }

  /// List of supported currencies - now using currency_picker's 150+ currencies
  static List<Currency> get allCurrencies {
    return CurrencyService().getAll();
  }

  /// Legacy supported currencies list (for backward compatibility)
  static const List<String> supportedCurrencies = ['USD', 'EUR', 'INR', 'THB'];
}
