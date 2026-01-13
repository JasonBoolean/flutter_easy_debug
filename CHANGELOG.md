## 0.0.4

*   **[NEW] General Logs**: Added "Logs" tab to display `debugPrint` and `EasyDebug.log` messages with auto-coloring (Error/Warning/Info).
*   **[NEW] Universal Http Support**: Added `EasyDebugHttpClient` wrapper to support standard `http` package debugging.
*   **[UI] Tab Navigation**: New specialized Header with Tabs (Network / Logs / Settings).
*   **[UI] Visual Polish**: Improved log list readability with zebra striping and smart copy.

## 0.0.3

*   **[DOCS] Update README**: Added comprehensive documentation for Environment Switcher feature.
*   **[FIX] UI Polish**: Fixed glassmorphism opacity issue in settings view (was too opaque).

## 0.0.2

*   **[NEW] Environment Switcher**: Added support for managing and switching API environments (e.g., Dev/Prod) at runtime.
    *   New `AppEnvironment` model.
    *   New `EasyDebugManager().init()` method with persistence support via `shared_preferences`.
    *   Reactive Base URL updates via `EasyDebugManager().currentEnvNotifier`.
*   **[FIX] Navigation Fallback**: Fixed navigation issues in projects without global `EasyDebugNavigatorObserver`. Now auto-falls back to `Navigator.of(context, rootNavigator: true)`.

## 0.0.1

*   Initial release of Easy Debug.
*   Pure Dart in-app network debugger for Dio.
*   Features: Floating overlay, glassmorphism UI, log filtering (All/Success/Error), copy to clipboard, and auto-clearing.
