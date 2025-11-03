import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/exchange_rate_service.dart';
import '../utils/currency_formatter.dart';
import '../app.dart'; // For settingsProvider

/// Provider for formatting amounts with currency conversion
final currencyFormatterProvider = Provider<CurrencyFormatterHelper>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  final exchangeRateService = ref.watch(exchangeRateServiceProvider);

  return settingsAsync.when(
    data: (settings) {
      return CurrencyFormatterHelper(
        baseCurrency: settings.baseCurrency,
        displayCurrency: settings.currency,
        exchangeRateService: exchangeRateService,
      );
    },
    loading: () {
      // Default to USD while loading
      return CurrencyFormatterHelper(
        baseCurrency: 'USD',
        displayCurrency: 'USD',
        exchangeRateService: exchangeRateService,
      );
    },
    error: (_, __) {
      // Default to USD on error
      return CurrencyFormatterHelper(
        baseCurrency: 'USD',
        displayCurrency: 'USD',
        exchangeRateService: exchangeRateService,
      );
    },
  );
});

/// Helper class for currency formatting with conversion
class CurrencyFormatterHelper {
  final String baseCurrency;
  final String displayCurrency;
  final ExchangeRateService exchangeRateService;

  CurrencyFormatterHelper({
    required this.baseCurrency,
    required this.displayCurrency,
    required this.exchangeRateService,
  });

  /// Format an amount with currency conversion
  /// [amount] is assumed to be in baseCurrency
  Future<String> format(double amount) async {
    return CurrencyFormatter.formatWithConversion(
      amount,
      baseCurrency,
      displayCurrency,
      exchangeRateService,
    );
  }

  /// Format an amount in compact notation with conversion (e.g., $1.2M)
  Future<String> formatCompact(double amount) async {
    return CurrencyFormatter.formatCompactWithConversion(
      amount,
      baseCurrency,
      displayCurrency,
      exchangeRateService,
    );
  }

  /// Format synchronously without conversion (for when conversion isn't needed)
  String formatSync(double amount) {
    return CurrencyFormatter.format(amount, displayCurrency);
  }

  /// Check if conversion is needed
  bool get needsConversion => baseCurrency != displayCurrency;

  /// Get exchange rate from base to display currency
  Future<double> getExchangeRate() async {
    if (!needsConversion) return 1.0;
    return exchangeRateService.getRate(baseCurrency, displayCurrency);
  }
}
