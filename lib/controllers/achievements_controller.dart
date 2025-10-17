import 'package:get/get.dart';
import 'package:games_api/games_api.dart';

enum AchievementCategory {
  all,
  tutorial,
  progress,
  skill,
  collection,
  score,
  time,
}

class AchievementsController extends GetxController {
  final GamesApiClient api = GamesApiClient.development();
  final String gameSlug = 'multiplex';

  final Rx<List<Achievement>> allAchievements = Rx<List<Achievement>>([]);
  final Rx<PlayerProfile?> profile = Rx<PlayerProfile?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<AchievementCategory> selectedCategory = AchievementCategory.all.obs;

  // Callback for when an achievement is unlocked
  Function(Achievement)? onAchievementUnlocked;

  @override
  void onInit() {
    super.onInit();
    fetchAchievements();
  }

  Future<void> fetchAchievements() async {
    isLoading.value = true;
    error.value = '';

    try {
      // Fetch all achievements
      final achievementsData = await api.games.getAchievements(gameSlug);
      allAchievements.value = achievementsData['achievements'] as List<Achievement>;

      // Fetch profile to get unlocked achievements
      final profileData = await api.games.getProfile(gameSlug);
      profile.value = profileData;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching achievements: $e');
      error.value = 'Failed to load achievements. Please try again.';
      Get.snackbar(
        'Error',
        error.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    await fetchAchievements();
  }

  void selectCategory(AchievementCategory category) {
    selectedCategory.value = category;
  }

  List<Achievement> get filteredAchievements {
    if (selectedCategory.value == AchievementCategory.all) {
      return allAchievements.value;
    }

    return allAchievements.value.where((achievement) {
      return getCategoryForAchievement(achievement) == selectedCategory.value;
    }).toList();
  }

  AchievementCategory getCategoryForAchievement(Achievement achievement) {
    final criteria = achievement.criteria;

    // Tutorial: Has small counts or first-time achievements
    if (criteria.containsKey('belts_placed') && (criteria['belts_placed'] as num) == 1) {
      return AchievementCategory.tutorial;
    }
    if (criteria.containsKey('operators_placed') && (criteria['operators_placed'] as num) == 1) {
      return AchievementCategory.tutorial;
    }
    if (criteria.containsKey('tiles_processed') && (criteria['tiles_processed'] as num) == 1) {
      return AchievementCategory.tutorial;
    }

    // Progress: Has level-related criteria
    if (criteria.containsKey('max_level') || criteria.containsKey('levels_completed')) {
      return AchievementCategory.progress;
    }

    // Skill: Has time or efficiency criteria
    if (criteria.containsKey('level_time_seconds') ||
        criteria.containsKey('max_belts_in_level') ||
        criteria.containsKey('perfect_levels')) {
      return AchievementCategory.skill;
    }

    // Collection: Has large counts of placed items (>= 50)
    if (criteria.containsKey('belts_placed') && (criteria['belts_placed'] as num) >= 50) {
      return AchievementCategory.collection;
    }
    if (criteria.containsKey('operators_placed') && (criteria['operators_placed'] as num) >= 50) {
      return AchievementCategory.collection;
    }
    if (criteria.containsKey('extractors_placed') && (criteria['extractors_placed'] as num) >= 50) {
      return AchievementCategory.collection;
    }
    if (criteria.containsKey('tiles_processed') && (criteria['tiles_processed'] as num) >= 50) {
      return AchievementCategory.collection;
    }

    // Score: Has total_score criteria
    if (criteria.containsKey('total_score')) {
      return AchievementCategory.score;
    }

    // Time: Has playtime_hours criteria
    if (criteria.containsKey('playtime_hours')) {
      return AchievementCategory.time;
    }

    // Default to progress if no clear category
    return AchievementCategory.progress;
  }

  Map<AchievementCategory, List<Achievement>> get achievementsByCategory {
    final Map<AchievementCategory, List<Achievement>> grouped = {
      AchievementCategory.tutorial: [],
      AchievementCategory.progress: [],
      AchievementCategory.skill: [],
      AchievementCategory.collection: [],
      AchievementCategory.score: [],
      AchievementCategory.time: [],
    };

    for (var achievement in allAchievements.value) {
      final category = getCategoryForAchievement(achievement);
      grouped[category]?.add(achievement);
    }

    return grouped;
  }

  bool isAchievementUnlocked(Achievement achievement) {
    if (profile.value == null) return false;
    return profile.value!.unlockedAchievements.any(
      (ua) => ua.achievementId == achievement.id && ua.unlockedAt != null,
    );
  }

  UserAchievement? getUnlockedAchievement(Achievement achievement) {
    if (profile.value == null) return null;
    try {
      return profile.value!.unlockedAchievements.firstWhere(
        (ua) => ua.achievementId == achievement.id,
      );
    } catch (e) {
      return null;
    }
  }

  int get unlockedCount {
    if (profile.value == null) return 0;
    return profile.value!.unlockedAchievements
        .where((ua) => ua.unlockedAt != null)
        .length;
  }

  int get totalCount => allAchievements.value.length;

  int get totalPoints {
    if (profile.value == null) return 0;
    return profile.value!.achievementPoints;
  }

  double getProgressPercentage(Achievement achievement) {
    final userAchievement = getUnlockedAchievement(achievement);
    if (userAchievement == null) return 0.0;

    if (userAchievement.unlockedAt != null) return 1.0;

    // Parse progress JSON
    try {
      final progressData = userAchievement.progress;
      if (progressData.isEmpty || progressData == '{}') return 0.0;

      // This is a simplified version, actual implementation may vary
      // based on how progress is calculated for each achievement
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  String getCategoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.all:
        return 'All';
      case AchievementCategory.tutorial:
        return 'Tutorial';
      case AchievementCategory.progress:
        return 'Progress';
      case AchievementCategory.skill:
        return 'Skill';
      case AchievementCategory.collection:
        return 'Collection';
      case AchievementCategory.score:
        return 'Score';
      case AchievementCategory.time:
        return 'Time';
    }
  }

  int getCategoryCount(AchievementCategory category) {
    if (category == AchievementCategory.all) {
      return allAchievements.value.length;
    }

    return allAchievements.value
        .where((a) => getCategoryForAchievement(a) == category)
        .length;
  }
}
