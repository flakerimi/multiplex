import 'dart:convert';
import 'user.dart';

/// Represents player statistics for a specific game
class PlayerStats {
  final int id;
  final int userId;
  final int gameId;
  final String stats;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;

  PlayerStats({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.stats,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      gameId: json['game_id'] ?? 0,
      stats: json['stats'] ?? '{}',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  /// Get stats data as a Map
  Map<String, dynamic> get statsData {
    try {
      return jsonDecode(stats);
    } catch (e) {
      return {};
    }
  }
}
