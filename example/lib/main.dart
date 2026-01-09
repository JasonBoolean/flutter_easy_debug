import 'package:flutter/material.dart';
import 'package:easy_debug/easy_debug.dart';
import 'package:dio/dio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Config Easy Debug
  EasyDebugManager().updateConfig(
    const EasyDebugConfig(clearOnNavigation: false, maxLogCount: 50),
  );

  // Initialize Environments
  await EasyDebugManager().init(
    environments: [
      const AppEnvironment(
        name: 'Production',
        baseUrl: 'https://jsonplaceholder.typicode.com',
        isDefault: true,
      ),
      const AppEnvironment(
        name: 'Development',
        baseUrl: 'https://dev.jsonplaceholder.typicode.com',
      ),
    ],
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Debug Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      navigatorObservers: [EasyDebugNavigatorObserver()],
      builder: (context, child) {
        return EasyDebugWidget(child: child!);
      },
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _dio.interceptors.add(EasyDebugDioInterceptor());

    // 1. Set initial BaseUrl
    _dio.options.baseUrl = EasyDebugManager().currentBaseUrl;

    // 2. Listen for environment changes
    EasyDebugManager().currentEnvNotifier.addListener(_onEnvChanged);
  }

  @override
  void dispose() {
    // 3. Remove listener to prevent memory leaks
    EasyDebugManager().currentEnvNotifier.removeListener(_onEnvChanged);
    super.dispose();
  }

  void _onEnvChanged() {
    final newEnv = EasyDebugManager().currentEnvNotifier.value;
    if (newEnv != null) {
      setState(() {
        _dio.options.baseUrl = newEnv.baseUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched to ${newEnv.name} Environment')),
      );
    }
  }

  Future<void> _makeRequest(String path, String method) async {
    // Now we just use the relative path, Dio handles the BaseUrl
    try {
      if (method == 'GET') {
        await _dio.get(path);
      } else if (method == 'POST') {
        await _dio.post(
          path,
          data: {'key': 'value', 'timestamp': DateTime.now().toIso8601String()},
        );
      }
    } catch (e) {
      // DioInterceptor catches errors automatically
      debugPrint('Request failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Easy Debug Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _makeRequest('/posts/1', 'GET'),
              child: const Text('GET Success (200)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _makeRequest('/posts', 'POST'),
              child: const Text('POST Success (201)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _makeRequest('/unknown-url', 'GET'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('GET 404 Error'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  _makeRequest('https://invalid-domain.test', 'GET'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Connection Error'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SecondPage()));
              },
              child: const Text('Navigate to Second Page'),
            ),
          ],
        ),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Second Page")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Dio().get('https://jsonplaceholder.typicode.com/comments?postId=1');
          },
          child: const Text("Make Request (No Interceptor)"),
        ),
      ),
    );
  }
}
