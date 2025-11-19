import 'package:flutter/material.dart';
import 'package:onecharge/core/storage/token_storage.dart';
import 'package:onecharge/core/storage/user_progress_storage.dart';
import 'package:onecharge/screen/home/home_screen.dart';
import 'package:onecharge/screen/login/phone_login.dart';
import 'package:onecharge/screen/onbording/onbording_screen.dart';
import 'package:onecharge/screen/vehicle/vehicle_selection.dart';
import 'package:onecharge/utils/onboarding_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // First check if user is already logged in (has a token)
    final token = await TokenStorage.readToken();

    if (!mounted) return;

    // If token exists, user is logged in - navigate to home screen
    if (token != null && token.isNotEmpty) {
      final hasCompletedVehicleSetup =
          await UserProgressStorage.isVehicleSetupCompleted();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => hasCompletedVehicleSetup
              ? HomeScreen()
              : const VehicleSelection(),
        ),
      );
      return;
    }

    // If no token, check onboarding status
    final isCompleted = await OnboardingService.isOnboardingCompleted();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            isCompleted ? const PhoneLogin() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
