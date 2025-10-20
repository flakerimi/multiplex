import 'user.dart';
import 'player_stats.dart';
import 'game_progress.dart';
import 'user_achievement.dart';

/// Represents a complete player profile for a game
class PlayerProfile {
  final User user;
  final PlayerStats stats;
  final GameProgress progress;
  final List<UserAchievement> unlockedAchievements;
  final int totalAchievements;
  final int achievementPoints;

  PlayerProfile({
    required this.user,
    required this.stats,
    required this.progress,
    required this.unlockedAchievements,
    required this.totalAchievements,
    required this.achievementPoints,
  });

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      user: User.fromJson(json['user'] ?? {}),
      stats: PlayerStats.fromJson(json['stats'] ?? {}),
      progress: GameProgress.fromJson(json['progress'] ?? {}),
      unlockedAchievements: (json['unlocked_achievements'] as List<dynamic>?)
          ?.map((e) => UserAchievement.fromJson(e))
          .toList() ?? [],
      totalAchievements: json['total_achievements'] ?? 0,
      achievementPoints: json['achievement_points'] ?? 0,
    );
  }
}
