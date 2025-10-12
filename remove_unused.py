#!/usr/bin/env python3
"""
Script to remove all unused methods identified by flutter analyze
"""

# Dashboard unused methods with their line numbers (from most recent error output)
DASHBOARD_UNUSED = [
    (2532, "_buildDeltaChipWithSparkline"),
    (2650, "_buildEnhancedGradeBadge"),
    (2674, "_buildQuieterDeltaChip"),
    (2730, "_getMainDriverText"),
    (2790, "_buildGradeBadge"),
    (2848, "_buildDeltaChip"),
    (2904, "_buildTimeframeChip"),
    (3025, "_getConfidenceColor"),
    (3093, "_buildEnhancedTrendIndicator"),
    (3136, "_hasIncompleteData"),
    (3143, "_showScoreTooltip"),
    (3693, "_getGradeColorForDiversification"),
    (3708, "_buildTrendIndicator"),
    (3738, "_getScoreGradientColors"),
    (3774, "_showScoreDetailsSheet"),
    (3832, "_showScoreQuickActions"),
]

print("Unused methods to remove from dashboard:")
for line, method in DASHBOARD_UNUSED:
    print(f"  Line {line}: {method}")

print(f"\nTotal: {len(DASHBOARD_UNUSED)} methods")
print("\nNOTE: These line numbers may shift as methods are removed.")
print("Recommendation: Remove methods from bottom to top to preserve line numbers.")
