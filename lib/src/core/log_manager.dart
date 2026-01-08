import 'package:flutter/foundation.dart';
import 'log_model.dart';

class EasyDebugManager {
  static final EasyDebugManager _instance = EasyDebugManager._internal();

  factory EasyDebugManager() => _instance;

  EasyDebugManager._internal();

  /// Configuration for the debug manager
  EasyDebugConfig config = const EasyDebugConfig();

  /// List of all network logs
  final ValueNotifier<List<NetworkLog>> logsNotifier = ValueNotifier([]);

  void updateConfig(EasyDebugConfig newConfig) {
    config = newConfig;
    _enforceMaxLogCount();
  }

  void addLog(NetworkLog log) {
    final currentLogs = List<NetworkLog>.from(logsNotifier.value);
    currentLogs.insert(0, log); // Add new logs to the top
    logsNotifier.value = currentLogs;
    _enforceMaxLogCount();
  }

  void updateLog(NetworkLog log) {
    // Notify listeners that a log has changed (e.g. response received)
    // Since objects are mutable, we just trigger the notifier if the list itself hasn't changed reference,
    // but usually it's better to replace the list or use a more granular notification.
    // For simplicity, we re-emit the list.
    logsNotifier.value = List.from(logsNotifier.value);
  }

  void clearLogs() {
    logsNotifier.value = [];
  }

  void _enforceMaxLogCount() {
    if (logsNotifier.value.length > config.maxLogCount) {
      logsNotifier.value = logsNotifier.value.sublist(0, config.maxLogCount);
    }
  }
}
