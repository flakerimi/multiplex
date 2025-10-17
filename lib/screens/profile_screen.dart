import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:games_api/games_api.dart';
import 'package:intl/intl.dart';
import '../controllers/profile_controller.dart';
import '../controllers/auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.profile.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value.isNotEmpty && controller.profile.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(controller.error.value),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: controller.refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeaderSection(controller, authController),
              const SizedBox(height: 24),
              _buildStatsSection(controller),
              const SizedBox(height: 24),
              _buildAchievementsSection(controller, context),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeaderSection(ProfileController controller, AuthController authController) {
    final user = authController.currentUser.value;
    if (user == null) return const SizedBox();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade100,
              child: user.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        user.avatarUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person, size: 50);
                        },
                      ),
                    )
                  : Text(
                      user.firstName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              user.username,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Obx(() => Text(
                        '${controller.achievementPoints} Achievement Points',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(ProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total Score',
              controller.totalScore.toString(),
              Icons.emoji_events,
              Colors.purple,
            ),
            _buildStatCard(
              'Levels Completed',
              controller.levelsCompleted.toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatCard(
              'Tiles Processed',
              controller.tilesProcessed.toString(),
              Icons.grid_on,
              Colors.blue,
            ),
            _buildStatCard(
              'Belts Placed',
              controller.beltsPlaced.toString(),
              Icons.linear_scale,
              Colors.orange,
            ),
            _buildStatCard(
              'Operators Placed',
              controller.operatorsPlaced.toString(),
              Icons.functions,
              Colors.red,
            ),
            _buildStatCard(
              'Extractors Placed',
              controller.extractorsPlaced.toString(),
              Icons.output,
              Colors.teal,
            ),
            _buildStatCard(
              'Total Playtime',
              controller.formattedPlaytime,
              Icons.access_time,
              Colors.indigo,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(ProfileController controller, BuildContext context) {
    return Obx(() {
      final unlocked = controller.unlockedAchievementsCount;
      final total = controller.totalAchievementsCount;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$unlocked/$total',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: total > 0 ? unlocked / total : 0,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 16),
          controller.allAchievements.value.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No achievements available'),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: controller.allAchievements.value.length,
                  itemBuilder: (context, index) {
                    final achievement = controller.allAchievements.value[index];
                    final isUnlocked = controller.isAchievementUnlocked(achievement);
                    final userAchievement = controller.getUnlockedAchievement(achievement);

                    return _buildAchievementBadge(
                      achievement,
                      isUnlocked,
                      userAchievement,
                      context,
                    );
                  },
                ),
        ],
      );
    });
  }

  Widget _buildAchievementBadge(
    Achievement achievement,
    bool isUnlocked,
    UserAchievement? userAchievement,
    BuildContext context,
  ) {
    return InkWell(
      onTap: () => _showAchievementDialog(achievement, isUnlocked, userAchievement, context),
      child: Card(
        elevation: 2,
        color: isUnlocked ? null : Colors.grey[300],
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    _getAchievementIcon(achievement.icon),
                    size: 48,
                    color: isUnlocked ? Colors.amber : Colors.grey[500],
                  ),
                  if (!isUnlocked)
                    Icon(
                      Icons.lock,
                      size: 24,
                      color: Colors.grey[700],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                achievement.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? Colors.black : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star,
                    size: 12,
                    color: isUnlocked ? Colors.amber : Colors.grey[500],
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${achievement.points}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isUnlocked ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAchievementIcon(String? iconName) {
    if (iconName == null) return Icons.emoji_events;

    switch (iconName.toLowerCase()) {
      case 'trophy':
        return Icons.emoji_events;
      case 'star':
        return Icons.star;
      case 'medal':
        return Icons.military_tech;
      case 'speed':
        return Icons.speed;
      case 'perfect':
        return Icons.verified;
      case 'master':
        return Icons.workspace_premium;
      default:
        return Icons.emoji_events;
    }
  }

  void _showAchievementDialog(
    Achievement achievement,
    bool isUnlocked,
    UserAchievement? userAchievement,
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getAchievementIcon(achievement.icon),
              color: isUnlocked ? Colors.amber : Colors.grey,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                achievement.name,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${achievement.points} points',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (isUnlocked && userAchievement?.unlockedAt != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Unlocked',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy').format(userAchievement!.unlockedAt!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!isUnlocked) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Locked',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
