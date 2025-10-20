import 'dart:convert';

/// Represents the game progress/save data for a player
class GameProgress {
  final int id;
  final int userId;
  final int gameId;
  final String data;
  final DateTime lastSyncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  GameProgress({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.data,
    required this.lastSyncedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GameProgress.fromJson(Map<String, dynamic> json) {
    return GameProgress(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      gameId: json['game_id'] ?? 0,
      data: json['data'] ?? '{}',
      lastSyncedAt: DateTime.parse(json['last_synced_at'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Check if there is any progress data
  bool get hasProgress {
    if (data == '{}') return false;
    try {
      final Map<String, dynamic> parsed = jsonDecode(data);
      return parsed.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get progress data as a Map
  Map<String, dynamic> get progressData {
    try {
      return jsonDecode(data);
    } catch (e) {
      return {};
    }
  }
}
