import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:games_api/games_api.dart';
import '../widgets/achievement_notification.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Queue for managing multiple notifications
  final Queue<Achievement> _notificationQueue = Queue<Achievement>();
  bool _isShowingNotification = false;
  OverlayEntry? _currentOverlay;
  BuildContext? _context;

  // Initialize with context (call this once in main app)
  void initialize(BuildContext context) {
    _context = context;
  }

  // Show achievement unlocked notification
  void showAchievementUnlocked(Achievement achievement) {
    // Add to queue
    _notificationQueue.add(achievement);

    // Process queue if not already showing a notification
    if (!_isShowingNotification) {
      _processQueue();
    }
  }

  // Process the notification queue
  void _processQueue() async {
    if (_notificationQueue.isEmpty) {
      _isShowingNotification = false;
      return;
    }

    _isShowingNotification = true;
    final achievement = _notificationQueue.removeFirst();

    await _showNotification(achievement);

    // Wait a bit before showing next notification
    await Future.delayed(const Duration(milliseconds: 500));

    // Process next in queue
    _processQueue();
  }

  // Show a single notification
  Future<void> _showNotification(Achievement achievement) async {
    if (_context == null || !_context!.mounted) {
      return;
    }

    final overlay = Overlay.of(_context!);

    // Create overlay entry
    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: AchievementNotification(
            achievement: achievement,
            onDismiss: _dismissCurrentNotification,
          ),
        ),
      ),
    );

    // Insert overlay
    overlay.insert(_currentOverlay!);

    // Wait for auto-dismiss or manual dismiss
    // The notification will call onDismiss when it's done
    // We'll use a completer pattern to wait
    await Future.delayed(const Duration(seconds: 5));
  }

  // Dismiss current notification
  void _dismissCurrentNotification() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  // Clear all pending notifications
  void clearQueue() {
    _notificationQueue.clear();
    _dismissCurrentNotification();
    _isShowingNotification = false;
  }

  // Get queue size
  int get queueSize => _notificationQueue.length;

  // Check if currently showing
  bool get isShowing => _isShowingNotification;
}
