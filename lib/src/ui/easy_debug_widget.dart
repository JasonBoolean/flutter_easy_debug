import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/log_manager.dart';
import '../core/config_model.dart';
import 'log_list_view.dart';
import 'general_logs_view.dart';

enum DebugViewMode { network, generalLogs, settings }

class EasyDebugWidget extends StatefulWidget {
  final Widget child;

  const EasyDebugWidget({super.key, required this.child});

  static void close(BuildContext context) {
    final state = context.findAncestorStateOfType<_EasyDebugWidgetState>();
    state?.closeConsole();
  }

  @override
  State<EasyDebugWidget> createState() => _EasyDebugWidgetState();
}

class _EasyDebugWidgetState extends State<EasyDebugWidget> {
  bool _isConsoleVisible = false;
  // Initial position for the floating button
  Offset _buttonPosition = const Offset(20, 100);
  LogFilter _currentFilter = LogFilter.all;
  DebugViewMode _viewMode = DebugViewMode.network;

  void closeConsole() {
    if (mounted) {
      setState(() {
        _isConsoleVisible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => Stack(
                children: [
                  if (_isConsoleVisible)
                    Positioned.fill(
                      child: Material(
                        color: Colors.black54,
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _isConsoleVisible = false),
                              child: Container(color: Colors.transparent),
                            ),
                            Positioned(
                              top: 100,
                              left: 20,
                              right: 20,
                              bottom: 50,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10.0,
                                    sigmaY: 10.0,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        _buildHeader(),
                                        Expanded(child: _buildContent()),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!_isConsoleVisible)
                    Positioned(
                      left: _buttonPosition.dx,
                      top: _buttonPosition.dy,
                      child: Draggable(
                        feedback: _buildFloatingButton(isDragging: true),
                        childWhenDragging: Container(),
                        onDragEnd: (details) {
                          setState(() {
                            _buttonPosition = details.offset;
                          });
                        },
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isConsoleVisible = true;
                            });
                          },
                          child: _buildFloatingButton(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_viewMode) {
      case DebugViewMode.network:
        return Column(
          children: [
            _buildFilterTabs(),
            Expanded(child: LogListView(filter: _currentFilter)),
          ],
        );
      case DebugViewMode.generalLogs:
        return const GeneralLogsView();
      case DebugViewMode.settings:
        return _buildSettingsView();
    }
  }

  Widget _buildFloatingButton({bool isDragging = false}) {
    return Material(
      color: Colors.transparent,
      elevation: isDragging ? 6 : 0,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          shape: BoxShape.circle,
          boxShadow: [
            if (!isDragging)
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: const Icon(Icons.bug_report, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Easy Debug',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              children: [
                _buildTabIcon(Icons.wifi, DebugViewMode.network),
                _buildTabIcon(Icons.notes, DebugViewMode.generalLogs),
                _buildTabIcon(Icons.settings, DebugViewMode.settings),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "Clear Logs",
            onPressed: () {
              EasyDebugManager().clearLogs();
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _isConsoleVisible = false),
          ),
        ],
      ),
    );
  }

  Widget _buildTabIcon(IconData icon, DebugViewMode mode) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.blueAccent : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingsView() {
    final manager = EasyDebugManager();
    if (manager.availableEnvironments.isEmpty) {
      return const Center(
        child: Text(
          "No environments configured.\nCall EasyDebugManager().init() first.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ValueListenableBuilder<AppEnvironment?>(
      valueListenable: manager.currentEnvNotifier,
      builder: (context, currentEnv, _) {
        return ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Select Environment",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ...manager.availableEnvironments.map((env) {
              final isSelected = currentEnv == env;
              return ListTile(
                title: Text(
                  env.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  env.baseUrl,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.blueAccent)
                    : const Icon(Icons.circle_outlined, color: Colors.grey),
                onTap: () {
                  manager.changeEnvironment(env);
                },
              );
            }),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Note: Switching environment might require a manual app restart if your Dio instance is not reactive.",
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildTabItem("All", LogFilter.all),
          const SizedBox(width: 8),
          _buildTabItem("Success", LogFilter.success),
          const SizedBox(width: 8),
          _buildTabItem("Error", LogFilter.error),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, LogFilter filter) {
    final bool isSelected = _currentFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentFilter = filter;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Colors.blueAccent
                  : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
