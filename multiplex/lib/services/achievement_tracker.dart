import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:games_api/games_api.dart';
import 'notification_service.dart';

/// Service class to track and unlock achievements based on player stats
class AchievementTracker {
  final GamesApiClient api;
  final String gameSlug;
  final NotificationService notificationService;

  // Cache of all achievements and unlocked achievements
  List<Achievement> _allAchievements = [];
  Set<int> _unlockedAchievementIds = {};

  // Track which achievements have been checked this session to avoid duplicate unlocks
  final Set<int> _unlockedThisSession = {};

  // Stream controller for achievement unlock events
  final _achievementUnlockedController = StreamController<Achievement>.broadcast();
  Stream<Achievement> get onAchievementUnlocked => _achievementUnlockedController.stream;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AchievementTracker({
    required this.api,
    required this.gameSlug,
    required this.notificationService,
  });

  /// Load all achievements and unlocked status from the API
  Future<void> loadAchievements() async {
    try {
      final achievementsData = await api.games.getAchievements(gameSlug);

      _allAchievements = achievementsData['achievements'] as List<Achievement>;
      final userAchievements = achievementsData['user_achievements'] as List<UserAchievement>;

      // Build set of unlocked achievement IDs
      _unlockedAchievementIds = userAchievements
          .where((ua) => ua.unlockedAt != null)
          .map((ua) => ua.achievementId)
          .toSet();

      _isInitialized = true;

      debugPrint('AchievementTracker: Loaded ${_allAchievements.length} achievements, ${_unlockedAchievementIds.length} unlocked');
    } catch (e) {
      debugPrint('Error loading achievements: $e');
      rethrow;
    }
  }

  /// Check all achievement criteria against current stats and unlock eligible achievements
  /// Returns the list of newly unlocked achievements
  Future<List<Achievement>> checkAchievements(Map<String, dynamic> stats) async {
    if (!_isInitialized) {
      debugPrint('AchievementTracker: Not initialized, skipping check');
      return [];
    }

    final newlyUnlocked = <Achievement>[];

    // Get achievements that aren't already unlocked
    final unlockableAchievements = _allAchievements.where(
      (achievement) => !_unlockedAchievementIds.contains(achievement.id),
    ).toList();

    for (final achievement in unlockableAchievements) {
      // Skip if already unlocked in this session
      if (_unlockedThisSession.contains(achievement.id)) {
        continue;
      }

      // Check if criteria is met
      if (_checkCriteria(achievement.criteria, stats)) {
        try {
          // Unlock via API
          await unlockAchievement(achievement.slug);
          newlyUnlocked.add(achievement);
        } catch (e) {
          debugPrint('Error unlocking achievement ${achievement.slug}: $e');
          // Continue checking other achievements even if one fails
        }
      }
    }

    return newlyUnlocked;
  }

  /// Check if achievement criteria is met
  /// Criteria format: {"belts_placed": 1, "total_score": 100}
  /// All criteria must be met (AND logic)
  bool _checkCriteria(Map<String, dynamic> criteria, Map<String, dynamic> stats) {
    if (criteria.isEmpty) {
      return false; // No criteria means not unlockable
    }

    // Check each criterion
    for (final entry in criteria.entries) {
      final key = entry.key;
      final requiredValue = entry.value;

      // Get current stat value (default to 0 if not present)
      final currentValue = stats[key];

      // Handle different value types
      if (requiredValue is num && currentValue is num) {
        // Numeric comparison: current must be >= required
        if (currentValue < requiredValue) {
          return false;
        }
      } else if (requiredValue is String && currentValue is String) {
        // String comparison: exact match
        if (currentValue != requiredValue) {
          return false;
        }
      } else if (requiredValue is bool && currentValue is bool) {
        // Boolean comparison: exact match
        if (currentValue != requiredValue) {
          return false;
        }
      } else {
        // Type mismatch or null value - criteria not met
        return false;
      }
    }

    // All criteria met
    return true;
  }

  /// Unlock an achievement via the API
  Future<UserAchievement> unlockAchievement(String achievementSlug) async {
    try {
      final userAchievement = await api.games.unlockAchievement(gameSlug, achievementSlug);

      // Update local cache
      _unlockedAchievementIds.add(userAchievement.achievementId);
      _unlockedThisSession.add(userAchievement.achievementId);

      // Find the achievement object
      final achievement = _allAchievements.firstWhere(
        (a) => a.id == userAchievement.achievementId,
        orElse: () => Achievement(
          id: userAchievement.achievementId,
          gameId: 0,
          name: 'Unknown Achievement',
          description: '',
          slug: achievementSlug,
          points: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Emit achievement unlocked event
      _achievementUnlockedController.add(achievement);

      // Show notification
      notificationService.showAchievementUnlocked(achievement);

      debugPrint('Achievement unlocked: ${achievement.name} (+${achievement.points} points)');

      return userAchievement;
    } catch (e) {
      debugPrint('Error unlocking achievement $achievementSlug: $e');
      rethrow;
    }
  }

  /// Batch unlock multiple achievements (optimization for multiple unlocks)
  Future<List<UserAchievement>> unlockAchievements(List<String> achievementSlugs) async {
    final results = <UserAchievement>[];

    for (final slug in achievementSlugs) {
      try {
        final result = await unlockAchievement(slug);
        results.add(result);
      } catch (e) {
        debugPrint('Error in batch unlock for $slug: $e');
        // Continue with other achievements
      }
    }

    return results;
  }

  /// Refresh achievements from API (useful after manual API operations)
  Future<void> refresh() async {
    await loadAchievements();
  }

  /// Check if a specific achievement is unlocked
  bool isUnlocked(int achievementId) {
    return _unlockedAchievementIds.contains(achievementId);
  }

  /// Get all unlockable achievements (not yet unlocked)
  List<Achievement> get unlockableAchievements {
    return _allAchievements.where(
      (achievement) => !_unlockedAchievementIds.contains(achievement.id),
    ).toList();
  }

  /// Get all unlocked achievements
  List<Achievement> get unlockedAchievements {
    return _allAchievements.where(
      (achievement) => _unlockedAchievementIds.contains(achievement.id),
    ).toList();
  }

  /// Get total achievements count
  int get totalAchievements => _allAchievements.length;

  /// Get unlocked achievements count
  int get unlockedCount => _unlockedAchievementIds.length;

  /// Calculate unlocked achievement points
  int get unlockedPoints {
    return unlockedAchievements.fold(0, (sum, achievement) => sum + achievement.points);
  }

  /// Dispose resources
  void dispose() {
    _achievementUnlockedController.close();
  }
}
