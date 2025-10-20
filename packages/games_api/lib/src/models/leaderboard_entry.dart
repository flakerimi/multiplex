import 'dart:convert';

class LeaderboardEntry {
  final int userId;
  final String username;
  final String? avatarUrl;
  final int totalScore;
  final int levelsCompleted;
  final Map<String, dynamic> stats;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.totalScore,
    required this.levelsCompleted,
    required this.stats,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final statsStr = json['stats'] as String?;
    final statsMap = statsStr != null && statsStr.isNotEmpty
        ? Map<String, dynamic>.from(_parseJson(statsStr))
        : <String, dynamic>{};

    return LeaderboardEntry(
      userId: user['id'] as int,
      username: user['username'] as String,
      avatarUrl: user['avatar_url'] as String?,
      totalScore: (statsMap['score'] as num?)?.toInt() ?? 0,
      levelsCompleted: (statsMap['levels_completed'] as num?)?.toInt() ?? 0,
      stats: statsMap,
    );
  }

  static dynamic _parseJson(String jsonStr) {
    try {
      return jsonDecode(jsonStr);
    } catch (e) {
      return {};
    }
  }

  String get initials {
    if (username.isEmpty) return '?';
    final parts = username.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username.substring(0, username.length > 2 ? 2 : username.length).toUpperCase();
  }
}
