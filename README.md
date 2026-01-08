# Easy Debug

A pure Dart, lightweight, and powerful in-app network debugger for Flutter.
`easy_debug` provides a floating overlay to monitor your Dio network requests in real-time, inspect details, and manage logs without connecting to an external debugger.

## Features

*   🚀 **Pure Dart**: No native dependencies, works on all Flutter platforms (Android, iOS, Web, Desktop).
*   📱 **Floating Overlay**: Always accessible Draggable floating button.
*   💎 **Glassmorphism UI**: Modern, semi-transparent design.
*   🔍 **Detailed Inspection**: View headers, body, timestamp, and duration for Requests and Responses.
*   📂 **Categorization**: Filter logs by "All", "Success", or "Error" tabs.
*   📋 **Smart Copy**: One-tap copy for Request/Response content (JSON formatted).
*   🧹 **Log Management**: Auto-clearing (optional) and manual clear support.

## Installation

Add `easy_debug` to your `pubspec.yaml`:

```yaml
dependencies:
  easy_debug:
    path: ./ # Or git/pub version
```

## Setup

### 1. Initialize & Wrap MaterialApp

Wrap your app with `EasyDebugWidget` using the `builder` property of `MaterialApp` (or `CupertinoApp`).
Also, add the `EasyDebugNavigatorObserver` to handle navigation correctly (e.g., closing overlay on page changes or handling context).

```dart
import 'package:easy_debug/easy_debug.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Debug Example',
      // 1. Wrap your app in the builder
      builder: (context, child) {
        return EasyDebugWidget(child: child!);
      },
      // 2. Add the navigator observer
      navigatorObservers: [
        EasyDebugNavigatorObserver(),
      ],
      home: const MyHomePage(),
    );
  }
}
```

### 2. Add Dio Interceptor

Attach the `EasyDebugDioInterceptor` to your Dio instance to start capturing network events.

```dart
final dio = Dio();

// Add the interceptor
dio.interceptors.add(EasyDebugDioInterceptor());
```

## Usage

*   **Open Console**: Tap the 🐞 floating button.
*   **Move Button**: Drag the floating button to any position.
*   **View Details**: Tap any log item to see full Request/Response details.
*   **Filter**: Use the tabs (All, Success, Error) to filter the list.
*   **Copy**: Inside the detail page, tap the generic Copy icon in the top right to copy the content of the *currently selected tab* (Request or Response).
*   **Clear Logs**: Tap the Trash icon in the console header.

## Configuration

You can configure global settings via `EasyDebugManager`.

```dart
EasyDebugManager().updateConfig(
  EasyDebugConfig(
    maxLogCount: 100, // Maximum logs to keep in memory
    clearOnNavigation: false, // Auto clear logs when navigating pages
  ),
);

## Author

Created by **JasonBoolean**.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
```
