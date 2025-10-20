import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game_progress.dart';
import '../models/player_stats.dart';
import '../models/achievement.dart';
import '../models/user_achievement.dart';
import '../models/player_profile.dart';
import 'auth_service.dart';

/// Service for game-related API endpoints
class GameService {
  final String baseUrl;
  final String apiKey;
  final AuthService authService;

  GameService({
    required this.baseUrl,
    required this.apiKey,
    required this.authService,
  });

  /// Get the game progress for the current user
  ///
  /// [gameSlug] - The unique slug identifier for the game
  /// Returns a [GameProgress] object containing the player's save data
  Future<GameProgress> getProgress(String gameSlug) async {
    final headers = await authService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/games/$gameSlug/progress'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return GameProgress.fromJson(data['progress']);
    } else {
      throw Exception('Failed to get progress: ${response.body}');
    }
  }

  /// Save game progress for the current user
  ///
  /// [gameSlug] - The unique slug identifier for the game
  /// [progressData] - The progress data to save
  /// Returns a [GameProgress] object with the updated save data
  Future<GameProgress> saveProgress(String gameSlug, Map<String, dynamic> progressData) async {
    final headers = await authService.getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/api/games/$gameSlug/progress'),
      headers: headers,
      body: jsonEncode(progressData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return GameProgress.fromJson(data['progress']);
    } else {
      throw Exception('Failed to save progress: ${response.body}');
    }
  }

  /// Get all achievements for a game and the user's unlocked achievements
  ///
  /// [gameSlug] - The unique slug identifier for the game
  /// Returns a Map with 'achievements' and 'user_achievements' lists
  Future<Map<String, dynamic>> getAchievements(String gameSlug) async {
    final headers = await authService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/games/$gameSlug/achievements'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'achievements': (data['achievements'] as List<dynamic>?)
            ?.map((e) => Achievement.fromJson(e))
            .toList() ?? [],
        'user_achievements': (data['user_achievements'] as List<dynamic>?)
            ?.map((e) => UserAchievement.fromJson(e))
            .toList() ?? [],
      };
    } else {
      throw Exception('Failed to get achievements: ${response.body}');
    }
  }

  /// Unlock an achievement for the current user
  ///
  /// [gameSlug] - The unique slug identifier for the game
  /// [achievementSlug] - The unique slug identifier for the achievement
  /// Returns a [UserAchievement] object representing the unlocked achievement
  Future<UserAchievement> unlockAchievement(String gameSlug, String achievementSlug) async {
    final headers = await authService.getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/api/games/$gameSlug/achievements/$achievementSlug'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserAchievement.fromJson(data['achievement']);
    } else {
      throw Exception('Failed to unlock achievement: ${response.body}');
    }
  }

  /// Get player statistics for a game
  ///
  /// [gameSlug] - The unique slug identifier for the game
  /// Returns a [PlayerStats] object containing the player's statistics
  Future<PlayerStats> getStats(String gameSlug) async {
    final headers = await authService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/games/$gameSlug/stats'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PlayerStats.fromJson(data['stats']);
    } else {
      throw Exception('Failed to get stats: ${response.body}');
    }
  }

  /// Update player statistics for a game
  ///
  /// [gameSlug] - The unique slug identifier for the game
  /// [statsData] - The statistics data to update
  /// Returns a [PlayerStats] object with the updated statistics
  Future<PlayerStats> updateStats(String gameSlug, Map<String, dynamic> statsData) async {
    final headers = await authService.getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/api/games/$gameSlug/stats'),
      headers: headers,
      body: jsonEncode(statsData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PlayerStats.fromJson(data['stats']);
    } else {
      throw Exception('Failed to update stats: ${response.body}');
    }
  }

  /// Get the leaderboard for a game
  ///
  /// [gameSlug] - The unique slug identifier for the game
  /// [limit] - The maximum number of entries to return (default: 10)
  /// Returns a list of [PlayerStats] objects representing the top players
  Future<List<PlayerStats>> getLeaderboard(String gameSlug, {int limit = 10}) async {
    final headers = await authService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/games/$gameSlug/leaderboard?limit=$limit'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['leaderboard'] as List<dynamic>?)
          ?.map((e) => PlayerStats.fromJson(e))
          .toList() ?? [];
    } else {
      throw Exception('Failed to get leaderboard: ${response.body}');
    }
  }

  /// Get the complete player profile for a game
  ///
  /// [gameSlug] - The unique slug identifier for the game
  /// Returns a [PlayerProfile] object containing user info, stats, progress, and achievements
  Future<PlayerProfile> getProfile(String gameSlug) async {
    final headers = await authService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/games/$gameSlug/profile'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PlayerProfile.fromJson(data['profile']);
    } else {
      throw Exception('Failed to get profile: ${response.body}');
    }
  }
}
