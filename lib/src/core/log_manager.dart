import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'log_model.dart';
import 'config_model.dart';

class EasyDebugManager {
  static final EasyDebugManager _instance = EasyDebugManager._internal();
  static const String _prefKeyEnvName = 'easy_debug_env_name';

  factory EasyDebugManager() => _instance;

  EasyDebugManager._internal();

  /// Configuration for the debug manager
  EasyDebugConfig config = const EasyDebugConfig();

  /// List of all network logs
  final ValueNotifier<List<NetworkLog>> logsNotifier = ValueNotifier([]);

  /// List of general logs (print/debugPrint)
  final ValueNotifier<List<GeneralLog>> generalLogsNotifier = ValueNotifier([]);

  /// Available environments
  List<AppEnvironment> _availableEnvironments = [];
  List<AppEnvironment> get availableEnvironments => _availableEnvironments;

  /// Current selected environment
  final ValueNotifier<AppEnvironment?> currentEnvNotifier = ValueNotifier(null);

  /// Initialize the manager with available environments
  Future<void> init({required List<AppEnvironment> environments}) async {
    // Intercept debugPrint
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        addGeneralLog(message);
      }
      originalDebugPrint(message, wrapWidth: wrapWidth);
    };

    _availableEnvironments = environments;
    if (_availableEnvironments.isEmpty) return;

    // Load persisted environment
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(_prefKeyEnvName);

    AppEnvironment? targetEnv;

    if (savedName != null) {
      targetEnv = _availableEnvironments.firstWhere(
        (e) => e.name == savedName,
        orElse: () => _availableEnvironments.firstWhere(
          (e) => e.isDefault,
          orElse: () => _availableEnvironments.first,
        ),
      );
    } else {
      // Default to the one marked as default, or the first one
      targetEnv = _availableEnvironments.firstWhere(
        (e) => e.isDefault,
        orElse: () => _availableEnvironments.first,
      );
    }

    currentEnvNotifier.value = targetEnv;
  }

  /// Change the current environment and persist it
  Future<void> changeEnvironment(AppEnvironment env) async {
    if (currentEnvNotifier.value == env) return;

    currentEnvNotifier.value = env;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyEnvName, env.name);
  }

  /// Helper to get current base URL
  String get currentBaseUrl => currentEnvNotifier.value?.baseUrl ?? '';

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

  void updateLog(NetworkLog updatedLog) {
    final currentLogs = List<NetworkLog>.from(logsNotifier.value);
    final index = currentLogs.indexWhere((l) => l.id == updatedLog.id);
    if (index != -1) {
      currentLogs[index] = updatedLog;
      logsNotifier.value = currentLogs;
    }
  }

  void addGeneralLog(String message) {
    final currentLogs = List<GeneralLog>.from(generalLogsNotifier.value);
    currentLogs.add(GeneralLog(timestamp: DateTime.now(), message: message));
    generalLogsNotifier.value = currentLogs;
    // We might want to enforce max count here too, but let's keep it simple for now or reuse logic
  }

  void clearLogs() {
    logsNotifier.value = [];
    generalLogsNotifier.value = [];
  }

  void _enforceMaxLogCount() {
    if (logsNotifier.value.length > config.maxLogCount) {
      logsNotifier.value = logsNotifier.value.sublist(0, config.maxLogCount);
    }
  }
}
