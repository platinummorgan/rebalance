import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Exchange rate service for currency conversion
/// Uses exchangerate-api.io (free tier: 1500 requests/month)
class ExchangeRateService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  static const String _cacheKey = 'exchange_rates_cache';
  static const String _cacheTimestampKey = 'exchange_rates_timestamp';
  static const Duration _cacheDuration =
      Duration(hours: 24); // Cache for 24 hours

  /// Get exchange rate from one currency to another
  /// Example: getRate('USD', 'EUR') returns ~0.92 (meaning 1 USD = 0.92 EUR)
  Future<double> getRate(String from, String to) async {
    if (from == to) return 1.0;

    try {
      final rates = await _getExchangeRates(from);
      return rates[to] ?? 1.0;
    } catch (e) {
      return 1.0; // Fallback to 1:1 if error
    }
  }

  /// Convert amount from one currency to another
  Future<double> convert(double amount, String from, String to) async {
    final rate = await getRate(from, to);
    final converted = amount * rate;
    return converted;
  }

  /// Get all exchange rates for a base currency
  Future<Map<String, double>> _getExchangeRates(String baseCurrency) async {
    // Try to get from cache first
    final cachedRates = await _getCachedRates(baseCurrency);
    if (cachedRates != null) {
      return cachedRates;
    }

    // Fetch from API
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/$baseCurrency'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Convert to double, handling both int and double from API
        final ratesData = data['rates'] as Map<String, dynamic>;
        final rates = ratesData
            .map((key, value) => MapEntry(key, (value as num).toDouble()));

        // Cache the rates
        await _cacheRates(baseCurrency, rates);

        return rates;
      } else {
        throw Exception(
          'Failed to load exchange rates: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Try to return stale cache if available
      final staleCache =
          await _getCachedRates(baseCurrency, ignoreExpiry: true);
      if (staleCache != null) {
        return staleCache;
      }
      rethrow;
    }
  }

  /// Get cached rates if available and not expired
  Future<Map<String, double>?> _getCachedRates(
    String baseCurrency, {
    bool ignoreExpiry = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cacheKey}_$baseCurrency';
      final timestampKey = '${_cacheTimestampKey}_$baseCurrency';

      final cachedData = prefs.getString(cacheKey);
      final timestamp = prefs.getInt(timestampKey);

      if (cachedData == null || timestamp == null) return null;

      // Check if cache is expired
      if (!ignoreExpiry) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final age = DateTime.now().difference(cacheTime);
        if (age > _cacheDuration) {
          return null;
        }
      }

      final rates = Map<String, double>.from(json.decode(cachedData));
      return rates;
    } catch (e) {
      return null;
    }
  }

  /// Cache exchange rates
  Future<void> _cacheRates(
    String baseCurrency,
    Map<String, double> rates,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cacheKey}_$baseCurrency';
      final timestampKey = '${_cacheTimestampKey}_$baseCurrency';

      await prefs.setString(cacheKey, json.encode(rates));
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Silent fail
    }
  }

  /// Clear all cached rates
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_cacheKey) || key.startsWith(_cacheTimestampKey)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // Silent fail
    }
  }
}

/// Provider for exchange rate service
final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  return ExchangeRateService();
});

/// Provider to get exchange rate between two currencies
final exchangeRateProvider =
    FutureProvider.family<double, ExchangeRatePair>((ref, pair) async {
  final service = ref.watch(exchangeRateServiceProvider);
  return await service.getRate(pair.from, pair.to);
});

/// Pair of currencies for exchange rate lookup
class ExchangeRatePair {
  final String from;
  final String to;

  const ExchangeRatePair(this.from, this.to);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExchangeRatePair &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => from.hashCode ^ to.hashCode;
}
