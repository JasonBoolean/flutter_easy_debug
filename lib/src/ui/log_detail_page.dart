import 'package:flutter/material.dart';
import 'dart:convert';
import '../core/log_model.dart';

import 'package:flutter/services.dart';

class LogDetailPage extends StatefulWidget {
  final NetworkLog log;

  const LogDetailPage({super.key, required this.log});

  @override
  State<LogDetailPage> createState() => _LogDetailPageState();
}

class _LogDetailPageState extends State<LogDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyContent() {
    String content = "";
    if (_tabController.index == 0) {
      // Request
      final headers = widget.log.request?.headers;
      final body = widget.log.request?.body;
      content = "URL: ${widget.log.url}\nMethod: ${widget.log.method}\n";
      content += "Headers: ${_formatJson(headers)}\n";
      content += "Body: ${_formatJson(body)}";
    } else {
      // Response
      final headers = widget.log.response?.headers;
      final body = widget.log.response?.body;
      content = "Status: ${widget.log.statusCode}\n";
      content += "Headers: ${_formatJson(headers)}\n";
      content += "Body: ${_formatJson(body)}";
    }

    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  String _formatJson(dynamic data) {
    if (data == null) return "null";
    try {
      if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
      return data.toString();
    } catch (_) {
      return data.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    return Scaffold(
      appBar: AppBar(
        title: Text('${log.method} Details'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: "Copy Current Tab",
            onPressed: _copyContent,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  log.url,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildTag(
                      log.statusCode.toString(),
                      _getStatusColor(log.statusCode),
                    ),
                    const SizedBox(width: 8),
                    Text('${log.durationMs ?? 0} ms'),
                    const SizedBox(width: 8),
                    Text(log.timestamp.toString().split('.')[0]),
                  ],
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "Request"),
              Tab(text: "Response"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildRequestView(), _buildResponseView()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestView() {
    final log = widget.log;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Headers"),
          _buildJsonViewer(log.request?.headers),
          const SizedBox(height: 16),
          _buildSectionTitle("Body"),
          _buildJsonViewer(log.request?.body),
        ],
      ),
    );
  }

  Widget _buildResponseView() {
    final log = widget.log;
    if (log.isError && log.response == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Error Occurred",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(log.error?.errorMessage ?? "Unknown Error"),
            const SizedBox(height: 8),
            Text(
              log.error?.stackTrace ?? "",
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Headers"),
          _buildJsonViewer(log.response?.headers),
          const SizedBox(height: 16),
          _buildSectionTitle("Body"),
          _buildJsonViewer(log.response?.body),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildJsonViewer(dynamic data) {
    final formatted = _formatJson(data);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SelectableText(
        formatted,
        style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
      ),
    );
  }

  Color _getStatusColor(int code) {
    if (code >= 200 && code < 300) return Colors.green;
    if (code >= 300 && code < 400) return Colors.orange;
    if (code >= 400) return Colors.red;
    return Colors.grey;
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
