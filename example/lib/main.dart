import 'package:flutter/material.dart';
import 'package:easy_debug/easy_debug.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

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
  late EasyDebugHttpClient _httpClient;

  @override
  void initState() {
    super.initState();
    _dio.interceptors.add(EasyDebugDioInterceptor());
    _httpClient = EasyDebugHttpClient(http.Client());

    // 1. Set initial BaseUrl
    _dio.options.baseUrl = EasyDebugManager().currentBaseUrl;

    // 2. Listen for environment changes
    EasyDebugManager().currentEnvNotifier.addListener(_onEnvChanged);
  }

  @override
  void dispose() {
    // 3. Remove listener to prevent memory leaks
    EasyDebugManager().currentEnvNotifier.removeListener(_onEnvChanged);
    _httpClient.close();
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

  Future<void> _makeHttpRequest() async {
    try {
      // Use hardcoded URL for simple http demo, or construct from baseUrl
      final baseUrl =
          EasyDebugManager().currentEnvNotifier.value?.baseUrl ??
          'https://jsonplaceholder.typicode.com';
      final url = Uri.parse('$baseUrl/todos/1');
      await _httpClient.get(url);
    } catch (e) {
      debugPrint('Http Request failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Easy Debug Demo')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader('Dio Requests'),
          ElevatedButton(
            onPressed: () => _makeRequest('/posts/1', 'GET'),
            child: const Text('GET Success (200)'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _makeRequest('/posts', 'POST'),
            child: const Text('POST Success (201)'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _makeRequest('/unknown-url', 'GET'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('GET 404 Error'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _makeRequest('https://invalid-domain.test', 'GET'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Connection Error'),
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('Http Package Requests'),
          ElevatedButton(
            onPressed: _makeHttpRequest,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Make http.Client Request'),
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('General Logs'),
          ElevatedButton(
            onPressed: () {
              debugPrint('This is a test log at ${DateTime.now()}');
              print(
                'This print() might be captured if we used runZoned, but for now debugPrint is safer.',
              );
              debugPrint('Warning: This is a simulated warning message.');
              debugPrint('Error: This is a simulated error message!');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text('Print General Logs (Info/Warn/Error)'),
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('Navigation'),
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
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
