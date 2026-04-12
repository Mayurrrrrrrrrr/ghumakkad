import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'providers/auth_provider.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/phone_login_screen.dart';
import 'screens/onboarding/profile_setup_screen.dart';
import 'screens/home/home_screen.dart';

class GhumakkadApp extends ConsumerWidget {
  const GhumakkadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Ghumakkad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        useMaterial3: true,
      ),
      home: _getHome(authState),
    );
  }

  Widget _getHome(AuthState state) {
    switch (state) {
      case AuthState.initial:
        return const SplashScreen();
      case AuthState.unauthenticated:
        return const OnboardingScreen();
      case AuthState.onboarding:
        return const ProfileSetupScreen();
      case AuthState.authenticated:
        return const HomeScreen();
      default:
        return const SplashScreen();
    }
  }
}
