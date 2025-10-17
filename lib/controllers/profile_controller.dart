import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:games_api/games_api.dart';

class ProfileController extends GetxController {
  final GamesApiClient api = GamesApiClient.development();
  final String gameSlug = 'multiplex';

  final Rx<PlayerProfile?> profile = Rx<PlayerProfile?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<List<Achievement>> allAchievements = Rx<List<Achievement>>([]);

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    isLoading.value = true;
    error.value = '';

    try {
      // Fetch profile data
      final profileData = await api.games.getProfile(gameSlug);
      profile.value = profileData;

      // Fetch all achievements to show locked ones too
      final achievementsData = await api.games.getAchievements(gameSlug);
      allAchievements.value = achievementsData['achievements'] as List<Achievement>;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      error.value = 'Failed to load profile. Please try again.';
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
    await fetchProfile();
  }

  // Helper to check if achievement is unlocked
  bool isAchievementUnlocked(Achievement achievement) {
    if (profile.value == null) return false;
    return profile.value!.unlockedAchievements.any(
      (ua) => ua.achievementId == achievement.id && ua.unlockedAt != null,
    );
  }

  // Get unlocked achievement for a specific achievement
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

  // Get stats helpers
  Map<String, dynamic> get stats {
    return profile.value?.stats.statsData ?? {};
  }

  int get totalScore => stats['total_score'] as int? ?? 0;
  int get levelsCompleted => stats['levels_completed'] as int? ?? 0;
  int get tilesProcessed => stats['tiles_processed'] as int? ?? 0;
  int get beltsPlaced => stats['belts_placed'] as int? ?? 0;
  int get operatorsPlaced => stats['operators_placed'] as int? ?? 0;
  int get extractorsPlaced => stats['extractors_placed'] as int? ?? 0;
  int get totalPlaytimeSeconds => stats['total_playtime_seconds'] as int? ?? 0;

  String get formattedPlaytime {
    final hours = totalPlaytimeSeconds ~/ 3600;
    final minutes = (totalPlaytimeSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  int get unlockedAchievementsCount {
    if (profile.value == null) return 0;
    return profile.value!.unlockedAchievements
        .where((ua) => ua.unlockedAt != null)
        .length;
  }

  int get totalAchievementsCount => profile.value?.totalAchievements ?? 0;
  int get achievementPoints => profile.value?.achievementPoints ?? 0;
}
