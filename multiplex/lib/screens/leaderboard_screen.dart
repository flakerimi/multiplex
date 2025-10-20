import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:games_api/games_api.dart';
import '../controllers/leaderboard_controller.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LeaderboardController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: Obx(() {
          if (controller.isLoading.value && controller.leaderboard.isEmpty) {
            return _buildLoadingState();
          }

          if (controller.hasError.value && controller.leaderboard.isEmpty) {
            return _buildErrorState(controller);
          }

          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: Column(
              children: [
                // Current User Rank Card
                if (controller.currentUserStats.value != null)
                  _buildCurrentUserCard(controller),

                // Leaderboard List
                Expanded(
                  child: controller.leaderboard.isEmpty
                      ? _buildEmptyState()
                      : _buildLeaderboardList(controller),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading leaderboard...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(LeaderboardController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load leaderboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No players yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to compete!',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserCard(LeaderboardController controller) {
    final stats = controller.currentUserStats.value!;
    final rank = controller.currentUserRank.value;
    final score = controller.getScore(stats);
    final levelsCompleted = controller.getLevelsCompleted(stats);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade700,
            Colors.purple.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.amber,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Rank',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stats.user?.username ?? 'You',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.stars,
                        size: 16,
                        color: Colors.amber.shade300,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$score pts',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.emoji_events,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$levelsCompleted levels',
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(LeaderboardController controller) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: controller.leaderboard.length,
      itemBuilder: (context, index) {
        final stats = controller.leaderboard[index];
        final rank = index + 1;
        return _buildLeaderboardEntry(controller, stats, rank);
      },
    );
  }

  Widget _buildLeaderboardEntry(
    LeaderboardController controller,
    PlayerStats stats,
    int rank,
  ) {
    final score = controller.getScore(stats);
    final levelsCompleted = controller.getLevelsCompleted(stats);
    final isTopThree = rank <= 3;
    final isCurrentUser = controller.currentUserStats.value?.userId == stats.userId;

    Color rankColor;
    IconData? medalIcon;

    if (rank == 1) {
      rankColor = Colors.amber.shade600;
      medalIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.grey.shade400;
      medalIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = Colors.brown.shade400;
      medalIcon = Icons.emoji_events;
    } else {
      rankColor = Colors.grey.shade600;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Colors.blue.shade50
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: Colors.blue.shade300, width: 2)
            : null,
        boxShadow: isTopThree
            ? [
                BoxShadow(
                  color: rankColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: SizedBox(
          width: 50,
          child: Row(
            children: [
              // Rank number
              SizedBox(
                width: 30,
                child: Center(
                  child: isTopThree && medalIcon != null
                      ? Icon(
                          medalIcon,
                          color: rankColor,
                          size: 28,
                        )
                      : Text(
                          '#$rank',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: rankColor,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        title: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: isTopThree ? rankColor : Colors.blue.shade600,
              child: stats.user?.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        stats.user!.avatarUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildInitialsAvatar(stats, rankColor);
                        },
                      ),
                    )
                  : _buildInitialsAvatar(stats, rankColor),
            ),
            const SizedBox(width: 12),
            // Username
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.user?.username ?? 'Player $rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isCurrentUser ? Colors.blue.shade900 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$levelsCompleted levels',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$score',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isTopThree ? rankColor : Colors.black87,
              ),
            ),
            Text(
              'points',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(PlayerStats stats, Color color) {
    final username = stats.user?.username ?? '?';
    String initials;

    if (username.contains(' ')) {
      final parts = username.split(' ');
      initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      initials = username.substring(0, username.length > 2 ? 2 : username.length).toUpperCase();
    }

    return Text(
      initials,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }
}
