import 'achievement.dart';

/// Represents an unlocked achievement for a user
class UserAchievement {
  final int id;
  final int userId;
  final int achievementId;
  final DateTime? unlockedAt;
  final String progress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Achievement? achievement;

  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    this.unlockedAt,
    required this.progress,
    required this.createdAt,
    required this.updatedAt,
    this.achievement,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      achievementId: json['achievement_id'] ?? 0,
      unlockedAt: json['unlocked_at'] != null ? DateTime.parse(json['unlocked_at']) : null,
      progress: json['progress'] ?? '{}',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      achievement: json['achievement'] != null ? Achievement.fromJson(json['achievement']) : null,
    );
  }
}
