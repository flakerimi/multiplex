import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:games_api/games_api.dart';

class AuthController extends GetxController {
  final GamesApiClient api = GamesApiClient.development();

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkAuth();
  }

  Future<void> checkAuth() async {
    isLoading.value = true;
    try {
      final authenticated = await api.auth.isAuthenticated();
      isAuthenticated.value = authenticated;

      if (authenticated) {
        currentUser.value = await api.auth.getUser();
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
      isAuthenticated.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    isLoading.value = true;
    try {
      final response = await api.auth.register(
        RegisterRequest(
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
          username: username,
        ),
      );

      currentUser.value = response.user;
      isAuthenticated.value = true;

      Get.snackbar(
        'Success',
        'Welcome, ${response.user.firstName}!',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Navigate to menu after registration
      Get.offAllNamed('/menu');

      return true;
    } catch (e) {
      Get.snackbar(
        'Registration Failed',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    debugPrint('[AuthController] Login starting for: $email');
    isLoading.value = true;
    try {
      debugPrint('[AuthController] Calling API login...');
      final response = await api.auth.login(
        LoginRequest(
          email: email,
          password: password,
        ),
      );

      debugPrint('[AuthController] Login response received');
      debugPrint('[AuthController] User: ${response.user}');
      debugPrint('[AuthController] User firstName: ${response.user.firstName}');
      debugPrint('[AuthController] User lastName: ${response.user.lastName}');

      currentUser.value = response.user;
      debugPrint('[AuthController] currentUser set');

      isAuthenticated.value = true;
      debugPrint('[AuthController] isAuthenticated set to true');

      Get.snackbar(
        'Success',
        'Welcome back, ${response.user.firstName}!',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Navigate to menu after login
      Get.offAllNamed('/menu');

      debugPrint('[AuthController] Login completed successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('[AuthController] Login error: $e');
      debugPrint('[AuthController] Stack trace: $stackTrace');
      Get.snackbar(
        'Login Failed',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    try {
      await api.auth.logout();
      currentUser.value = null;
      isAuthenticated.value = false;

      Get.snackbar(
        'Logged Out',
        'See you next time!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
