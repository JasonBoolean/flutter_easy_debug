import 'package:flutter/material.dart';
import 'package:easy_debug/easy_debug.dart';
import 'package:dio/dio.dart';

void main() {
  // Config Easy Debug
  EasyDebugManager().updateConfig(
    const EasyDebugConfig(clearOnNavigation: false, maxLogCount: 50),
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
  }

  Future<void> _makeRequest(String url, String method) async {
    try {
      if (method == 'GET') {
        await _dio.get(url);
      } else if (method == 'POST') {
        await _dio.post(
          url,
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
              onPressed: () => _makeRequest(
                'https://jsonplaceholder.typicode.com/posts/1',
                'GET',
              ),
              child: const Text('GET Success (200)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _makeRequest(
                'https://jsonplaceholder.typicode.com/posts',
                'POST',
              ),
              child: const Text('POST Success (201)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _makeRequest(
                'https://jsonplaceholder.typicode.com/unknown-url',
                'GET',
              ),
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
