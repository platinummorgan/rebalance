/// Lightweight debug logger that is stripped in release mode.
/// Provides an opt-in channel mechanism for filtering categories.
class DebugLog {
  DebugLog._();

  /// Enable or disable specific channels (leave empty for all when in debug).
  static final Set<String> enabledChannels = <String>{};

  /// Global master switch (can be toggled by a settings/debug panel later).
  static bool enabled = true;

  /// Log a structured message under a channel.
  static void log(String channel, String message) {
    assert(() {
      if (!enabled) return true; // silently skip
      if (enabledChannels.isNotEmpty && !enabledChannels.contains(channel)) {
        return true; // filtered out
      }
      // ignore: avoid_print
      print('[$channel] $message');
      return true;
    }());
  }
}
