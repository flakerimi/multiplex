import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:games_api/games_api.dart';
import 'package:intl/intl.dart';
import '../controllers/achievements_controller.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AchievementsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.allAchievements.value.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value.isNotEmpty && controller.allAchievements.value.isEmpty) {
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
          child: Column(
            children: [
              _buildHeader(controller),
              _buildCategoryTabs(controller),
              Expanded(
                child: _buildAchievementsList(controller, context),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(AchievementsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                        '${controller.unlockedCount} of ${controller.totalCount} Unlocked',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Obx(() => Text(
                          '${controller.totalPoints}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() => LinearProgressIndicator(
                value: controller.totalCount > 0
                    ? controller.unlockedCount / controller.totalCount
                    : 0,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                minHeight: 8,
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(AchievementsController controller) {
    final categories = [
      AchievementCategory.all,
      AchievementCategory.tutorial,
      AchievementCategory.progress,
      AchievementCategory.skill,
      AchievementCategory.collection,
      AchievementCategory.score,
      AchievementCategory.time,
    ];

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Obx(() {
            final isSelected = controller.selectedCategory.value == category;
            final count = controller.getCategoryCount(category);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(
                  '${controller.getCategoryName(category)} ($count)',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    controller.selectCategory(category);
                  }
                },
                backgroundColor: Colors.grey.shade200,
                selectedColor: Colors.blue,
                checkmarkColor: Colors.white,
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildAchievementsList(AchievementsController controller, BuildContext context) {
    return Obx(() {
      final achievements = controller.filteredAchievements;

      if (achievements.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No achievements in this category',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          final isUnlocked = controller.isAchievementUnlocked(achievement);
          final userAchievement = controller.getUnlockedAchievement(achievement);

          return _buildAchievementCard(
            achievement,
            isUnlocked,
            userAchievement,
            controller,
            context,
          );
        },
      );
    });
  }

  Widget _buildAchievementCard(
    Achievement achievement,
    bool isUnlocked,
    UserAchievement? userAchievement,
    AchievementsController controller,
    BuildContext context,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: isUnlocked ? Colors.white : Colors.grey.shade200,
      child: InkWell(
        onTap: () => _showAchievementDetails(
          achievement,
          isUnlocked,
          userAchievement,
          controller,
          context,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isUnlocked ? Colors.amber.shade100 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      _getAchievementIcon(achievement.icon),
                      size: 36,
                      color: isUnlocked ? Colors.amber : Colors.grey.shade500,
                    ),
                    if (!isUnlocked)
                      Icon(
                        Icons.lock,
                        size: 24,
                        color: Colors.grey.shade700,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? Colors.black : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isUnlocked ? Colors.grey.shade700 : Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isUnlocked ? Colors.amber.shade100 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 14,
                                color: isUnlocked ? Colors.amber : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${achievement.points}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked ? Colors.black : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isUnlocked && userAchievement?.unlockedAt != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM d, yyyy').format(userAchievement!.unlockedAt!),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
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
      case 'beginner':
        return Icons.school;
      case 'expert':
        return Icons.psychology;
      case 'time':
        return Icons.access_time;
      case 'collection':
        return Icons.collections;
      default:
        return Icons.emoji_events;
    }
  }

  void _showAchievementDetails(
    Achievement achievement,
    bool isUnlocked,
    UserAchievement? userAchievement,
    AchievementsController controller,
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: isUnlocked ? Colors.amber.shade100 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            _getAchievementIcon(achievement.icon),
                            size: 56,
                            color: isUnlocked ? Colors.amber : Colors.grey.shade500,
                          ),
                          if (!isUnlocked)
                            Icon(
                              Icons.lock,
                              size: 36,
                              color: Colors.grey.shade700,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      achievement.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          '${achievement.points} Points',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isUnlocked && userAchievement?.unlockedAt != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Unlocked',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('EEEE, MMMM d, yyyy').format(userAchievement!.unlockedAt!),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock, color: Colors.grey.shade700, size: 32),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Locked',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'How to Unlock',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildCriteriaList(achievement.criteria),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildCriteriaList(Map<String, dynamic> criteria) {
    if (criteria.isEmpty) {
      return [
        const Text(
          'Complete specific in-game actions to unlock this achievement.',
          style: TextStyle(fontSize: 14),
        ),
      ];
    }

    final List<Widget> widgets = [];
    criteria.forEach((key, value) {
      String label = _formatCriteriaLabel(key);
      String valueText = _formatCriteriaValue(key, value);

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$label: $valueText',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    });

    return widgets;
  }

  String _formatCriteriaLabel(String key) {
    switch (key) {
      case 'belts_placed':
        return 'Belts Placed';
      case 'operators_placed':
        return 'Operators Placed';
      case 'extractors_placed':
        return 'Extractors Placed';
      case 'tiles_processed':
        return 'Tiles Processed';
      case 'levels_completed':
        return 'Levels Completed';
      case 'max_level':
        return 'Reach Level';
      case 'total_score':
        return 'Total Score';
      case 'playtime_hours':
        return 'Playtime';
      case 'level_time_seconds':
        return 'Complete Level in';
      case 'max_belts_in_level':
        return 'Max Belts in Level';
      case 'perfect_levels':
        return 'Perfect Levels';
      default:
        return key.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }

  String _formatCriteriaValue(String key, dynamic value) {
    switch (key) {
      case 'playtime_hours':
        return '$value hours';
      case 'level_time_seconds':
        final numValue = value as num;
        final minutes = numValue ~/ 60;
        final seconds = numValue % 60;
        return '${minutes}m ${seconds}s';
      case 'total_score':
        return value.toString();
      default:
        return value.toString();
    }
  }
}
