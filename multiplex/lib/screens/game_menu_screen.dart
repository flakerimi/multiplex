import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/game_menu_controller.dart';
import '../controllers/auth_controller.dart';

class GameMenuScreen extends StatefulWidget {
  const GameMenuScreen({super.key});

  @override
  State<GameMenuScreen> createState() => _GameMenuScreenState();
}

class _GameMenuScreenState extends State<GameMenuScreen> {
  late final GameMenuController controller;
  late final AuthController authController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(GameMenuController());
    authController = Get.find<AuthController>();

    // Refresh progress whenever this screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[GameMenuScreen] Refreshing progress...');
      controller.checkProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.black87,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with user info and logout
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() {
                      final user = authController.currentUser.value;
                      return Text(
                        'Welcome, ${user?.firstName ?? 'Player'}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white70),
                      tooltip: 'Logout',
                      onPressed: () async {
                        await authController.logout();
                      },
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Colors.purple.shade300,
                              Colors.blue.shade300,
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'MULTIPLEXED',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 60),

                        // Loading indicator or menu buttons
                        Obx(() {
                          if (controller.isLoading.value) {
                            return const Column(
                              children: [
                                CircularProgressIndicator(
                                  color: Colors.white70,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Loading...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              // Continue Game button (only if progress exists)
                              if (controller.hasProgress.value)
                                _MenuButton(
                                  icon: Icons.play_arrow,
                                  label: 'Continue Game',
                                  onTap: controller.navigateToContinueGame,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade600,
                                      Colors.green.shade800,
                                    ],
                                  ),
                                ),

                              if (controller.hasProgress.value)
                                const SizedBox(height: 16),

                              // New Game button
                              _MenuButton(
                                icon: Icons.add_circle,
                                label: 'New Game',
                                onTap: controller.navigateToNewGame,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade600,
                                    Colors.blue.shade800,
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Profile button
                              _MenuButton(
                                icon: Icons.person,
                                label: 'Profile',
                                onTap: controller.navigateToProfile,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.shade600,
                                    Colors.purple.shade800,
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Leaderboard button
                              _MenuButton(
                                icon: Icons.leaderboard,
                                label: 'Leaderboard',
                                onTap: controller.navigateToLeaderboard,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.shade600,
                                    Colors.orange.shade800,
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Achievements button
                              _MenuButton(
                                icon: Icons.emoji_events,
                                label: 'Achievements',
                                onTap: controller.navigateToAchievements,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber.shade600,
                                    Colors.amber.shade800,
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Gradient gradient;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.gradient,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    debugPrint('[MenuButton] Tap down on: ${widget.label}');
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    debugPrint('[MenuButton] Tap up on: ${widget.label}');
    _controller.reverse();
    debugPrint('[MenuButton] Calling onTap for: ${widget.label}');
    widget.onTap();
    debugPrint('[MenuButton] onTap completed for: ${widget.label}');
  }

  void _handleTapCancel() {
    debugPrint('[MenuButton] Tap cancelled on: ${widget.label}');
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 320,
          height: 70,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
