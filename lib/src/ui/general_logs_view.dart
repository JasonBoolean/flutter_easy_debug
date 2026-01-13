import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/log_manager.dart';
import '../core/log_model.dart';

class GeneralLogsView extends StatelessWidget {
  const GeneralLogsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<GeneralLog>>(
      valueListenable: EasyDebugManager().generalLogsNotifier,
      builder: (context, logs, child) {
        if (logs.isEmpty) {
          return const Center(
            child: Text(
              "No logs yet.\nTry debugPrint('header', wrapWidth: 1024) or EasyDebug.log()",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          );
        }

        // Auto-scroll to bottom behavior is nice for terminals,
        // but for now let's just stick to a reversed list like Network logs
        // (Newest on top is usually better for mobile inspection)
        final reversedLogs = logs.reversed.toList();

        return ListView.builder(
          padding: EdgeInsets.zero, // Remove padding to let shading fill width
          itemCount: reversedLogs.length,
          itemBuilder: (context, index) {
            final log = reversedLogs[index];
            return _buildLogItem(context, log, index);
          },
        );
      },
    );
  }

  Widget _buildLogItem(BuildContext context, GeneralLog log, int index) {
    final isEven = index % 2 == 0;
    // Increased contrast from grey[50] to grey[200]
    final backgroundColor = isEven ? Colors.white : Colors.grey[200];
    final textColor = _getLogColor(log.message);

    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: () {
          _copyToClipboard(context, log);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timestamp column
              SizedBox(
                width: 60,
                child: Text(
                  _formatTime(log.timestamp),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Separator line
              Container(
                width: 1,
                height: 14,
                color: Colors.grey.withValues(alpha: 0.2),
                margin: const EdgeInsets.only(top: 2, right: 8),
              ),
              // Message column
              Expanded(
                child: Text(
                  log.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                    fontFamily: 'Courier',
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLogColor(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('error') ||
        lower.contains('exception') ||
        lower.contains('fail')) {
      return Colors.red[700]!;
    }
    if (lower.contains('warning') || lower.contains('warn')) {
      return Colors.orange[800]!;
    }
    if (lower.contains('info') || lower.contains('debug')) {
      return Colors.blue[700]!;
    }
    return Colors.black87;
  }

  void _copyToClipboard(BuildContext context, GeneralLog log) {
    Clipboard.setData(ClipboardData(text: log.message));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Log copied to clipboard'),
        duration: Duration(milliseconds: 600),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
  }
}
