import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

enum ExchangeRateSource {
  sameCurrency,
  live,
  cacheFresh,
  cacheStale,
  fallbackOneToOne,
}

class ExchangeRateInfo {
  final double rate;
  final ExchangeRateSource source;
  final DateTime? fetchedAt;
  final String? warning;

  const ExchangeRateInfo({
    required this.rate,
    required this.source,
    this.fetchedAt,
    this.warning,
  });

  bool get isStale => source == ExchangeRateSource.cacheStale;
  bool get isFallback => source == ExchangeRateSource.fallbackOneToOne;
}

class _CachedRatesEntry {
  final Map<String, double> rates;
  final DateTime fetchedAt;
  final bool isStale;

  const _CachedRatesEntry({
    required this.rates,
    required this.fetchedAt,
    required this.isStale,
  });
}

/// Exchange rate service for currency conversion
/// Uses exchangerate-api.io (free tier: 1500 requests/month)
class ExchangeRateService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  static const String _cacheKey = 'exchange_rates_cache';
  static const String _cacheTimestampKey = 'exchange_rates_timestamp';
  static const Duration _cacheDuration =
      Duration(hours: 24); // Cache for 24 hours

  /// Rich lookup result including data source and stale/fallback status.
  Future<ExchangeRateInfo> getRateInfo(String from, String to) async {
    if (from == to) {
      return const ExchangeRateInfo(
        rate: 1.0,
        source: ExchangeRateSource.sameCurrency,
      );
    }

    // Use non-stale cache first.
    final cached = await _getCachedRatesEntry(from, ignoreExpiry: false);
    if (cached != null && cached.rates.containsKey(to)) {
      return ExchangeRateInfo(
        rate: cached.rates[to] ?? 1.0,
        source: ExchangeRateSource.cacheFresh,
        fetchedAt: cached.fetchedAt,
      );
    }

    // Fetch from live API.
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/$from'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ratesData = data['rates'] as Map<String, dynamic>;
        final rates = ratesData
            .map((key, value) => MapEntry(key, (value as num).toDouble()));

        await _cacheRates(from, rates);

        final liveRate = rates[to];
        if (liveRate != null) {
          return ExchangeRateInfo(
            rate: liveRate,
            source: ExchangeRateSource.live,
            fetchedAt: DateTime.now(),
          );
        }
      }
    } catch (_) {
      // handled by stale fallback path below
    }

    // Fall back to stale cache if present.
    final stale = await _getCachedRatesEntry(from, ignoreExpiry: true);
    if (stale != null && stale.rates.containsKey(to)) {
      return ExchangeRateInfo(
        rate: stale.rates[to] ?? 1.0,
        source: stale.isStale
            ? ExchangeRateSource.cacheStale
            : ExchangeRateSource.cacheFresh,
        fetchedAt: stale.fetchedAt,
        warning: stale.isStale
            ? 'Using stale exchange rate; live rates are currently unavailable.'
            : null,
      );
    }

    // Final fallback (explicitly marked so UI can avoid misleading conversion).
    return const ExchangeRateInfo(
      rate: 1.0,
      source: ExchangeRateSource.fallbackOneToOne,
      warning:
          'Live exchange rates unavailable. Showing base-currency value instead.',
    );
  }

  /// Get exchange rate from one currency to another
  /// Example: getRate('USD', 'EUR') returns ~0.92 (meaning 1 USD = 0.92 EUR)
  Future<double> getRate(String from, String to) async {
    final info = await getRateInfo(from, to);
    return info.rate;
  }

  /// Convert amount from one currency to another
  Future<double> convert(double amount, String from, String to) async {
    final info = await getRateInfo(from, to);
    return amount * info.rate;
  }

  Future<_CachedRatesEntry?> _getCachedRatesEntry(
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

      final fetchedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final age = DateTime.now().difference(fetchedAt);
      final isStale = age > _cacheDuration;

      if (!ignoreExpiry && isStale) return null;

      final rates = Map<String, double>.from(json.decode(cachedData));
      return _CachedRatesEntry(
        rates: rates,
        fetchedAt: fetchedAt,
        isStale: isStale,
      );
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

final exchangeRateInfoProvider =
    FutureProvider.family<ExchangeRateInfo, ExchangeRatePair>((ref, pair) async {
  final service = ref.watch(exchangeRateServiceProvider);
  return await service.getRateInfo(pair.from, pair.to);
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
