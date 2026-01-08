import 'package:flutter/widgets.dart';
import 'log_manager.dart';

class EasyDebugNavigatorObserver extends NavigatorObserver {
  static EasyDebugNavigatorObserver? _instance;

  // Expose the navigator state publicly
  static NavigatorState? get navigatorState => _instance?.navigator;

  EasyDebugNavigatorObserver() {
    _instance = this;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _checkAndClearLogs();
    super.didPush(route, previousRoute);
  }

  void _checkAndClearLogs() {
    if (EasyDebugManager().config.clearOnNavigation) {
      EasyDebugManager().clearLogs();
    }
  }
}
