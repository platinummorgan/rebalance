import 'package:flutter/material.dart';
// import 'package:flutter/gestures.dart';
import '../../../data/calculators/financial_health.dart';

/// Reusable financial health pill removed from the large dashboard screen.
/// All logic decisions (delta calculation, severity color, subtitle, etc.)
/// are passed in so this widget stays purely presentational.
class FinancialHealthPill extends StatelessWidget {
  final FinancialHealthResult result;
  final int scoreDelta;
  final String timeframe;
  final String statusLabel;
  final String subtitle; // e.g. Weakest: Liquidity 73/100
  final Color severityColor;
  final VoidCallback onDetails;
  final VoidCallback onTrend;

  const FinancialHealthPill({
    super.key,
    required this.result,
    required this.scoreDelta,
    required this.timeframe,
    required this.statusLabel,
    required this.subtitle,
    required this.severityColor,
    required this.onDetails,
    required this.onTrend,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Show a small AlertDialog with two simple choices. This keeps the UX simple
        // and avoids requiring a long-press.
        debugPrint('FinancialHealthPill: Tap - showing selection dialog');
        showDialog<void>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('View'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.show_chart),
                  title: const Text('Trend'),
                  onTap: () {
                    Navigator.of(dialogCtx).pop();
                    Future.microtask(onTrend);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Financial score'),
                  onTap: () {
                    Navigator.of(dialogCtx).pop();
                    Future.microtask(onDetails);
                  },
                ),
              ],
            ),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Tooltip(
        message: 'Tap for details • Press & hold for trend',
        waitDuration: const Duration(milliseconds: 800),
        preferBelow: false,
        child: Semantics(
          label:
              'Overall financial health score ${result.grade.name}, ${result.score}. '
              '${scoreDelta != 0 ? '${scoreDelta > 0 ? 'Increased' : 'Decreased'} by ${scoreDelta.abs()} points over $timeframe.' : ''} '
              '$statusLabel. $subtitle.',
          hint: 'Tap for details, press and hold for trend chart',
          button: true,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 56,
              minWidth: 56,
              maxWidth: 280,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: severityColor.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          result.grade.name,
                          style: TextStyle(
                            color: severityColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '•',
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.6),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${result.score}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                    ),
                    if (scoreDelta != 0) ...[
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Icon(
                            scoreDelta > 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            size: 12,
                            color: scoreDelta > 0
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${scoreDelta > 0 ? '+' : ''}$scoreDelta',
                            style: TextStyle(
                              color: scoreDelta > 0
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '($timeframe)',
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.4),
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 11,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Overall',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.5),
                        fontSize: 9,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
