import 'package:get/get.dart';
import 'package:games_api/games_api.dart';
import 'package:flutter/material.dart';

class GameMenuController extends GetxController {
  final GamesApiClient api = GamesApiClient.development();

  final RxBool isLoading = false.obs;
  final RxBool hasProgress = false.obs;
  final Rx<GameProgress?> gameProgress = Rx<GameProgress?>(null);

  static const String gameSlug = 'multiplex';

  @override
  void onInit() {
    super.onInit();
    checkProgress();
  }

  Future<void> checkProgress() async {
    isLoading.value = true;
    try {
      debugPrint('[GameMenuController] Fetching progress for: $gameSlug');
      final progress = await api.games.getProgress(gameSlug);
      debugPrint('[GameMenuController] Progress fetched: ${progress.data}');
      debugPrint('[GameMenuController] Progress hasProgress: ${progress.hasProgress}');
      debugPrint('[GameMenuController] Progress progressData: ${progress.progressData}');
      gameProgress.value = progress;
      hasProgress.value = progress.hasProgress;
    } catch (e) {
      debugPrint('Failed to check progress: $e');
      hasProgress.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  void navigateToContinueGame() {
    debugPrint('[GameMenuController] Navigating to continue game');
    debugPrint('[GameMenuController] Has progress: ${hasProgress.value}');
    debugPrint('[GameMenuController] Progress data: ${gameProgress.value?.progressData}');
    // Navigate to game screen with existing progress
    Get.toNamed('/game', arguments: {'progress': gameProgress.value?.progressData});
    debugPrint('[GameMenuController] Get.toNamed called successfully');
  }

  Future<void> navigateToNewGame() async {
    debugPrint('[GameMenuController] New game button clicked');
    if (hasProgress.value) {
      debugPrint('[GameMenuController] Has progress, showing confirmation dialog');
      // Show confirmation dialog
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Start New Game?'),
          content: const Text(
            'Starting a new game will overwrite your current progress. Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Start New Game'),
            ),
          ],
        ),
      );

      debugPrint('[GameMenuController] Dialog result: $confirmed');
      if (confirmed == true) {
        debugPrint('[GameMenuController] Confirmed, navigating to game with null progress');
        debugPrint('[GameMenuController] Calling Get.toNamed("/game")...');
        Get.toNamed('/game', arguments: {'progress': null});
        debugPrint('[GameMenuController] Get.toNamed called successfully');
      } else {
        debugPrint('[GameMenuController] User cancelled new game');
      }
    } else {
      debugPrint('[GameMenuController] No progress, navigating directly');
      debugPrint('[GameMenuController] Calling Get.toNamed("/game")...');
      Get.toNamed('/game', arguments: {'progress': null});
      debugPrint('[GameMenuController] Get.toNamed called successfully');
    }
  }

  void navigateToProfile() {
    debugPrint('[GameMenuController] Navigating to profile');
    debugPrint('[GameMenuController] Calling Get.toNamed("/profile")...');
    Get.toNamed('/profile');
    debugPrint('[GameMenuController] Get.toNamed called successfully');
  }

  void navigateToLeaderboard() {
    debugPrint('[GameMenuController] Navigating to leaderboard');
    debugPrint('[GameMenuController] Calling Get.toNamed("/leaderboard")...');
    Get.toNamed('/leaderboard');
    debugPrint('[GameMenuController] Get.toNamed called successfully');
  }

  void navigateToAchievements() {
    debugPrint('[GameMenuController] Navigating to achievements');
    debugPrint('[GameMenuController] Calling Get.toNamed("/achievements")...');
    Get.toNamed('/achievements');
    debugPrint('[GameMenuController] Get.toNamed called successfully');
  }
}
