import 'package:flutter/material.dart';
import '../core/log_manager.dart';
import '../core/log_model.dart';
import '../core/easy_debug_navigator_observer.dart';
import 'easy_debug_widget.dart';
import 'log_detail_page.dart';

enum LogFilter { all, success, error }

class LogListView extends StatelessWidget {
  final LogFilter filter;

  const LogListView({super.key, this.filter = LogFilter.all});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<NetworkLog>>(
      valueListenable: EasyDebugManager().logsNotifier,
      builder: (context, allLogs, child) {
        // Apply filter
        final logs = allLogs.where((log) {
          switch (filter) {
            case LogFilter.all:
              return true;
            case LogFilter.success:
              return !log.isError &&
                  log.statusCode >= 200 &&
                  log.statusCode < 400;
            case LogFilter.error:
              return log.isError || log.statusCode >= 400;
          }
        }).toList();

        if (logs.isEmpty) {
          return const Center(child: Text("No logs found."));
        }
        return ListView.separated(
          itemCount: logs.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final log = logs[index];
            return _buildLogItem(context, log);
          },
        );
      },
    );
  }

  Widget _buildLogItem(BuildContext context, NetworkLog log) {
    Color statusColor;
    final statusCode = log.statusCode;
    if (statusCode >= 200 && statusCode < 300) {
      statusColor = Colors.green;
    } else if (statusCode >= 300 && statusCode < 400) {
      statusColor = Colors.orange;
    } else if (statusCode >= 400) {
      statusColor = Colors.red;
    } else if (log.isError) {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.grey;
    }

    return ListTile(
      dense: true,
      onTap: () {
        EasyDebugWidget.close(context);
        EasyDebugNavigatorObserver.navigatorState?.push(
          MaterialPageRoute(builder: (_) => LogDetailPage(log: log)),
        );
      },
      leading: Container(
        width: 50,
        alignment: Alignment.center,
        child: Text(
          log.method.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: _getMethodColor(log.method),
          ),
        ),
      ),
      title: Text(
        log.url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor, width: 0.5),
            ),
            child: Text(
              statusCode > 0 ? statusCode.toString() : '---',
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormatting.formatTimestamp(log.timestamp),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
      trailing: Text(
        log.durationMs != null ? '${log.durationMs} ms' : '',
        style: TextStyle(
          fontSize: 11,
          color: (log.durationMs ?? 0) > 1000
              ? Colors.orange
              : Colors.grey[600],
        ),
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.purple;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}

class DateFormatting {
  static String formatTimestamp(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
  }
}
