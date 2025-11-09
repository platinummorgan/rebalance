import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/currency_formatter.dart';
import '../services/exchange_rate_service.dart';
import '../app.dart';

/// A Text widget that automatically converts currency amounts based on user settings
class CurrencyText extends ConsumerStatefulWidget {
  final double amount;
  final TextStyle? style;
  final bool compact;
  final bool showSign; // Show + or - prefix
  final bool useAbsoluteValue; // Use absolute value of amount

  const CurrencyText(
    this.amount, {
    super.key,
    this.style,
    this.compact = false,
    this.showSign = false,
    this.useAbsoluteValue = false,
  });

  @override
  ConsumerState<CurrencyText> createState() => _CurrencyTextState();
}

class _CurrencyTextState extends ConsumerState<CurrencyText> {
  String? _cachedConversion;
  String? _lastKey;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    final displayAmount =
        widget.useAbsoluteValue ? widget.amount.abs() : widget.amount;
    final prefix = widget.showSign ? (widget.amount >= 0 ? '+' : '−') : '';

    return settingsAsync.when(
      loading: () => Text(
        '$prefix${widget.compact ? CurrencyFormatter.formatCompact(displayAmount, 'USD') : CurrencyFormatter.format(displayAmount, 'USD')}',
        style: widget.style,
      ),
      error: (_, __) => Text(
        '$prefix${widget.compact ? CurrencyFormatter.formatCompact(displayAmount, 'USD') : CurrencyFormatter.format(displayAmount, 'USD')}',
        style: widget.style,
      ),
      data: (settings) {
        // Handle null/empty baseCurrency for existing users
        final baseCurrency =
            (settings.baseCurrency.isEmpty) ? 'USD' : settings.baseCurrency;
        final displayCurrency = settings.currency;

        // If same currency, no conversion needed
        if (baseCurrency == displayCurrency) {
          return Text(
            '$prefix${widget.compact ? CurrencyFormatter.formatCompact(displayAmount, displayCurrency) : CurrencyFormatter.format(displayAmount, displayCurrency)}',
            style: widget.style,
          );
        }

        // Create a unique key for this conversion
        final key =
            '${widget.amount}_${baseCurrency}_${displayCurrency}_${widget.compact}';

        // If we have a cached result for this exact conversion, use it
        if (_lastKey == key && _cachedConversion != null) {
          return Text(
            '$prefix$_cachedConversion',
            style: widget.style,
          );
        }

        // Otherwise, perform the conversion
        _performConversion(displayAmount, baseCurrency, displayCurrency, key);

        // While converting, show base currency
        return Text(
          '$prefix${widget.compact ? CurrencyFormatter.formatCompact(displayAmount, baseCurrency) : CurrencyFormatter.format(displayAmount, baseCurrency)}',
          style: widget.style,
        );
      },
    );
  }

  Future<void> _performConversion(
    double amount,
    String from,
    String to,
    String key,
  ) async {
    final exchangeRateService = ref.read(exchangeRateServiceProvider);

    try {
      print('CurrencyText: Converting $amount from $from to $to'); // DEBUG
      final result = widget.compact
          ? await CurrencyFormatter.formatCompactWithConversion(
              amount,
              from,
              to,
              exchangeRateService,
            )
          : await CurrencyFormatter.formatWithConversion(
              amount,
              from,
              to,
              exchangeRateService,
            );

      print('CurrencyText: Conversion result: $result'); // DEBUG
      if (mounted && _lastKey != key) {
        setState(() {
          _cachedConversion = result;
          _lastKey = key;
        });
      }
    } catch (e) {
      print('CurrencyText: Conversion failed: $e'); // DEBUG
      // Silent fail - will display base currency
    }
  }
}
