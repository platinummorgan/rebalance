/// MetricsService: provides a thin abstraction layer for logging events,
/// counters and timings. Current implementation is a no-op suitable for
/// offline/privacy-first MVP; can be swapped for Sentry / self-hosted later.
abstract class MetricsService {
  static MetricsService instance = NoopMetricsService();

  void logEvent(String name, {Map<String, Object?> properties = const {}});
  void incrementCounter(String name, {int by = 1});
  void logTiming(
    String name,
    Duration duration, {
    Map<String, Object?> properties = const {},
  });
}

class NoopMetricsService implements MetricsService {
  @override
  void incrementCounter(String name, {int by = 1}) {
    // no-op
  }

  @override
  void logEvent(String name, {Map<String, Object?> properties = const {}}) {
    // no-op
  }

  @override
  void logTiming(
    String name,
    Duration duration, {
    Map<String, Object?> properties = const {},
  }) {
    // no-op
  }
}
