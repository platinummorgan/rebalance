import 'package:flutter/material.dart';
import '../../../generated/app_localizations.dart';

class RiskNudgeCard extends StatefulWidget {
  final String title;
  final String diagnosis;
  final String action;
  final String ctaText;
  final VoidCallback onCTA;
  final VoidCallback? onWhy;
  final VoidCallback? onSnooze;
  final VoidCallback? onDismiss;
  final MaterialColor severityColor;
  final bool showPro;
  final bool isProgress;
  final String? progressText;
  final List<String>? personalizationChips;
  final DateTime? detectedAt; // New: timestamp for "spotted 2h ago"
  final ValueChanged<String>?
      onChipTap; // New: make chips tappable and receive the chip label

  const RiskNudgeCard({
    super.key,
    required this.title,
    required this.diagnosis,
    required this.action,
    required this.ctaText,
    required this.onCTA,
    this.onWhy,
    this.onSnooze,
    this.onDismiss,
    this.severityColor = Colors.amber,
    this.showPro = false,
    this.isProgress = false,
    this.progressText,
    this.personalizationChips,
    this.detectedAt,
    this.onChipTap,
  });

  @override
  State<RiskNudgeCard> createState() => _RiskNudgeCardState();
}

class _RiskNudgeCardState extends State<RiskNudgeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;
  bool _isExpanded = false; // Collapsed by default

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 8),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleCTA() async {
    setState(() => _isLoading = true);

    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 1500));

    widget.onCTA();

    setState(() => _isLoading = false);

    // Show success toast
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.ctaText} · 6-month glidepath'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatTimestamp(DateTime detectedAt) {
    final loc = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(detectedAt);

    if (difference.inMinutes < 60) {
      return '${loc.spotted} ${difference.inMinutes}m ${loc.ago}';
    } else if (difference.inHours < 24) {
      return '${loc.spotted} ${difference.inHours}h ${loc.ago}';
    } else if (difference.inDays < 7) {
      return '${loc.spotted} ${difference.inDays}d ${loc.ago}';
    } else {
      return '${loc.spotted} ${(difference.inDays / 7).floor()}w ${loc.ago}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.severityColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16), // radius.card = 16
                border: Border.all(
                  color: widget.severityColor.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4, // elevation.2 = 4dp for alert cards
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with severity chip, title, timestamp and menu
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        // Severity chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.severityColor.shade600,
                            borderRadius: BorderRadius.circular(
                              10,
                            ), // Design token: radius.chip = 10
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.highRisk,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ), // Consistent 8px gap (space.sm)
                        // Hazard icon nudged 2px right from chip
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Icon(
                            Icons.warning_amber_outlined,
                            color: widget.severityColor.shade700,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 8), // Consistent 8px gap
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              // Timestamp if available
                              if (widget.detectedAt != null)
                                Text(
                                  _formatTimestamp(widget.detectedAt!),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Expand/collapse chevron
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns: _isExpanded ? 0.5 : 0,
                          child: Icon(
                            Icons.expand_more,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expandable content section
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _isExpanded
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Breathing space below title (6-8px)
                              const SizedBox(height: 8),

                              // Personalization chips with desaturated styling
                              if (widget.personalizationChips != null) ...[
                                Wrap(
                                  spacing: 8, // Equal spacing between chips
                                  runSpacing: 6,
                                  children: widget.personalizationChips!
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final index = entry.key;
                                    final chip = entry.value;
                                    final isFirstChip = index ==
                                        0; // "US Equity 42.5%" stays prominent

                                    return GestureDetector(
                                      onTap: widget.onChipTap != null
                                          ? () => widget.onChipTap!(chip)
                                          : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          // Tone down neutral chips while keeping High Risk dominant
                                          color: isFirstChip
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                                  .withValues(alpha: 0.7)
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(
                                                    alpha: 0.08,
                                                  ), // onSurface 8% background
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ), // Design token: radius.chip = 10
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline
                                                .withValues(alpha: 0.18),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              chip,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isFirstChip
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(
                                                          alpha: 0.65,
                                                        ), // onSurface 65% text for readability
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            // Add tappable indicator for chips if onChipTap is provided
                                            if (widget.onChipTap != null) ...[
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.chevron_right,
                                                size: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                // Extra breathing space below chip row (14px total for action line separation)
                                const SizedBox(height: 14),
                              ],

                              // Primary action line with inline Why? link
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isNarrow = constraints.maxWidth < 600;

                                  if (isNarrow) {
                                    // Mobile: Stack button under action line
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Action line with inline Why?
                                        _buildActionLineWithWhy(
                                          context,
                                          isNarrow,
                                        ),
                                        const SizedBox(height: 6),
                                        // Explanatory diagnosis
                                        Text(
                                          widget.diagnosis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 14,
                                        ), // 12-16px spacing
                                        // Full-width button on mobile
                                        SizedBox(
                                          width: double.infinity,
                                          child: _buildCTAButton(
                                            context,
                                            isNarrow,
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    // Desktop: Right-aligned button next to action line
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .center, // Center button with action line
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Action line with inline Why?
                                                  _buildActionLineWithWhy(
                                                    context,
                                                    isNarrow,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  // Explanatory diagnosis
                                                  Text(
                                                    widget.diagnosis,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Button vertically centered with the entire left column content
                                            Align(
                                              alignment: Alignment.topCenter,
                                              child: _buildCTAButton(
                                                context,
                                                isNarrow,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionLineWithWhy(BuildContext context, bool isNarrow) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          widget.action,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (widget.onWhy != null) ...[
          const Text(' — '),
          GestureDetector(
            onTap: widget.onWhy,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.why,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(width: 2), // 2px closer to text
                const Icon(
                  Icons.help_outline,
                  size: 16,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCTAButton(BuildContext context, bool isNarrow) {
    if (widget.isProgress && widget.progressText != null) {
      return Column(
        crossAxisAlignment:
            isNarrow ? CrossAxisAlignment.stretch : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
            children: [
              SizedBox(
                width: 80,
                child: LinearProgressIndicator(
                  value: 0.33,
                  backgroundColor: widget.severityColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(
                    widget.severityColor.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.progressText!,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: widget.onCTA,
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.severityColor.shade700,
              side: BorderSide(color: widget.severityColor.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Adjust plan'),
          ),
        ],
      );
    } else {
      return FilledButton.icon(
        onPressed: _isLoading ? null : _handleCTA,
        style: FilledButton.styleFrom(
          backgroundColor: widget.severityColor == Colors.green
              ? Colors.green.shade600
              : Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          side: widget.severityColor == Colors.green
              ? BorderSide(
                  color: Colors.green.shade700.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Icon(Icons.auto_fix_high, size: 18),
        label: _isLoading
            ? const Text('Creating...')
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.ctaText,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.showPro) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Pro',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  // CTA arrow to indicate primary action
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                  ),
                ],
              ),
      );
    }
  }
}
