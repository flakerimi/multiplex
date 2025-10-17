import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'controllers/auth_controller.dart';
import 'game/multiplex.dart';
import 'screens/achievements_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/game_menu_screen.dart';
import 'screens/game_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  // Initialize GetX dependencies
  Get.put(AuthController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Multiplex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthWrapper(),
      getPages: [
        GetPage(name: '/menu', page: () => const GameMenuScreen()),
        GetPage(name: '/game', page: () => GameScreen(game: Multiplex())),
        GetPage(name: '/profile', page: () => const ProfileScreen()),
        GetPage(name: '/leaderboard', page: () => const LeaderboardScreen()),
        GetPage(name: '/achievements', page: () => const AchievementsScreen()),
      ],
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      // Show loading indicator while checking auth
      if (authController.isLoading.value && authController.currentUser.value == null) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Show auth screen if not authenticated
      if (!authController.isAuthenticated.value) {
        return const AuthScreen();
      }

      // Show game menu if authenticated
      return const GameMenuScreen();
    });
  }
}

