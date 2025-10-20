import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:games_api/games_api.dart';
import 'auth_controller.dart';

class LeaderboardController extends GetxController {
  final GamesApiClient api = GamesApiClient.development();
  final AuthController authController = Get.find();

  final RxList<PlayerStats> leaderboard = <PlayerStats>[].obs;
  final Rx<PlayerStats?> currentUserStats = Rx<PlayerStats?>(null);
  final RxInt currentUserRank = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  Timer? _autoRefreshTimer;
  static const String gameSlug = 'multiplex';
  static const int refreshInterval = 30; // seconds

  @override
  void onInit() {
    super.onInit();
    loadLeaderboard();
    _startAutoRefresh();
  }

  @override
  void onClose() {
    _autoRefreshTimer?.cancel();
    super.onClose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: refreshInterval),
      (_) => loadLeaderboard(silent: true),
    );
  }

  Future<void> loadLeaderboard({bool silent = false}) async {
    if (!silent) {
      isLoading.value = true;
    }
    hasError.value = false;
    errorMessage.value = '';

    try {
      // Fetch leaderboard (top 100)
      final entries = await api.games.getLeaderboard(gameSlug, limit: 100);
      leaderboard.value = entries;

      // Find current user's position
      _findCurrentUserRank();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      debugPrint('Error loading leaderboard: $e');
    } finally {
      if (!silent) {
        isLoading.value = false;
      }
    }
  }

  void _findCurrentUserRank() {
    final currentUser = authController.currentUser.value;
    if (currentUser == null) return;

    final index = leaderboard.indexWhere(
      (stats) => stats.userId == currentUser.id,
    );

    if (index != -1) {
      currentUserStats.value = leaderboard[index];
      currentUserRank.value = index + 1;
    } else {
      currentUserStats.value = null;
      currentUserRank.value = 0;
    }
  }

  @override
  Future<void> refresh() async {
    await loadLeaderboard();
  }

  String getRankSuffix(int rank) {
    if (rank <= 0) return '';
    if (rank % 100 >= 11 && rank % 100 <= 13) {
      return 'th';
    }
    switch (rank % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String getFormattedRank(int rank) {
    if (rank <= 0) return 'Unranked';
    return '#$rank';
  }

  int getScore(PlayerStats stats) {
    return (stats.statsData['total_score'] as num?)?.toInt() ?? 0;
  }

  int getLevelsCompleted(PlayerStats stats) {
    return (stats.statsData['levels_completed'] as num?)?.toInt() ?? 0;
  }
}
