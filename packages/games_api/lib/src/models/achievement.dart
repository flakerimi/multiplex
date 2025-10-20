import 'dart:convert';

/// Represents an achievement in a game
class Achievement {
  final int id;
  final int gameId;
  final String name;
  final String description;
  final String slug;
  final int points;
  final String? icon;
  final Map<String, dynamic> criteria;
  final DateTime createdAt;
  final DateTime updatedAt;

  Achievement({
    required this.id,
    required this.gameId,
    required this.name,
    required this.description,
    required this.slug,
    required this.points,
    this.icon,
    Map<String, dynamic>? criteria,
    required this.createdAt,
    required this.updatedAt,
  }) : criteria = criteria ?? {};

  factory Achievement.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> criteriaMap = {};
    if (json['criteria'] != null) {
      if (json['criteria'] is String) {
        try {
          criteriaMap = jsonDecode(json['criteria']);
        } catch (e) {
          criteriaMap = {};
        }
      } else if (json['criteria'] is Map) {
        criteriaMap = Map<String, dynamic>.from(json['criteria']);
      }
    }

    return Achievement(
      id: json['id'] ?? 0,
      gameId: json['game_id'] ?? 0,
      name: json['name'] ?? json['title'] ?? '',
      description: json['description'] ?? '',
      slug: json['slug'] ?? '',
      points: json['points'] ?? 0,
      icon: json['icon'],
      criteria: criteriaMap,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
