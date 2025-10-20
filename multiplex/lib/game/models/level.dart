import 'dart:convert';

import 'package:flutter/services.dart';

class Position {
  final int x;
  final int y;

  Position({required this.x, required this.y});

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      x: json['x'] as int,
      y: json['y'] as int,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

class NumberSpawn {
  final int value;
  final int count;

  NumberSpawn({
    required this.value,
    required this.count,
  });

  factory NumberSpawn.fromJson(Map<String, dynamic> json) {
    return NumberSpawn(
      value: json['value'] as int,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'count': count,
      };
}

class Level {
  final int id;
  final int targetNumber;
  final int targetValue;
  final String description;
  final List<String> unlockedTools;
  final List<String> unlockedOperators;
  final List<NumberSpawn> numberSpawns;

  Level({
    required this.id,
    required this.targetNumber,
    required this.targetValue,
    required this.description,
    required this.unlockedTools,
    required this.unlockedOperators,
    required this.numberSpawns,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'] as int,
      targetNumber: json['targetNumber'] as int,
      targetValue: json['targetValue'] as int,
      description: json['description'] as String,
      unlockedTools: List<String>.from(json['unlockedTools'] as List),
      unlockedOperators:
          List<String>.from(json['unlockedOperators'] as List),
      numberSpawns: json['numberSpawns'] != null
          ? (json['numberSpawns'] as List)
              .map((spawn) => NumberSpawn.fromJson(spawn as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetNumber': targetNumber,
        'targetValue': targetValue,
        'description': description,
        'unlockedTools': unlockedTools,
        'unlockedOperators': unlockedOperators,
        'numberSpawns': numberSpawns.map((spawn) => spawn.toJson()).toList(),
      };
}

class LevelsData {
  final List<Level> levels;

  LevelsData({required this.levels});

  factory LevelsData.fromJson(Map<String, dynamic> json) {
    return LevelsData(
      levels: (json['levels'] as List)
          .map((level) => Level.fromJson(level as Map<String, dynamic>))
          .toList(),
    );
  }

  static Future<LevelsData> loadFromAssets() async {
    final String jsonString =
        await rootBundle.loadString('assets/levels.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    return LevelsData.fromJson(jsonData);
  }

  Map<String, dynamic> toJson() => {
        'levels': levels.map((level) => level.toJson()).toList(),
      };
}
