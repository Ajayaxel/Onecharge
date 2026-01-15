import 'package:flutter/material.dart';
import 'package:onecharge/core/storage/token_storage.dart';
import 'package:onecharge/core/storage/user_progress_storage.dart';
import 'package:onecharge/core/storage/vehicle_storage.dart';
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
    // Add a small delay to ensure SharedPreferences is fully initialized
    await Future.delayed(const Duration(milliseconds: 300));

    print('🔍 [SplashScreen] Checking authentication status...');

    // Try reading token multiple times to ensure SharedPreferences is ready
    String? token;
    for (int i = 0; i < 3; i++) {
      token = await TokenStorage.readToken();
      if (token != null && token.isNotEmpty) {
        break;
      }
      if (i < 2) {
        print(
          '⚠️ [SplashScreen] Token not found, retrying... (attempt ${i + 1}/3)',
        );
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    print(
      '🔍 [SplashScreen] Token check result: ${token != null ? "Token found (length: ${token.length})" : "No token found"}',
    );

    if (!mounted) return;

    // If token exists, user is logged in - check vehicle setup
    if (token != null && token.isNotEmpty) {
      print('✅ [SplashScreen] Token exists, user is authenticated');

      // Check both the flag and actual vehicle data
      final hasCompletedVehicleSetup =
          await UserProgressStorage.isVehicleSetupCompleted();
      final vehicleName = await VehicleStorage.getVehicleName();
      final hasVehicleData = vehicleName != null && vehicleName.isNotEmpty;

      print(
        '🔍 [SplashScreen] Vehicle setup completed flag: $hasCompletedVehicleSetup',
      );
      print(
        '🔍 [SplashScreen] Vehicle data exists: $hasVehicleData (name: $vehicleName)',
      );

      if (!mounted) return;

      // Navigate to HomeScreen only if vehicle is actually saved
      final destination = hasVehicleData
          ? const HomeScreen()
          : const VehicleSelection();

      print(
        '🚀 [SplashScreen] Navigating to: ${hasVehicleData ? "HomeScreen" : "VehicleSelection"}',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
      return;
    }

    // If no token, check onboarding status
    print('⚠️ [SplashScreen] No token found, checking onboarding status...');
    final isCompleted = await OnboardingService.isOnboardingCompleted();
    print('🔍 [SplashScreen] Onboarding completed: $isCompleted');

    if (!mounted) return;

    final destination = isCompleted
        ? const PhoneLogin()
        : const OnboardingScreen();
    print(
      '🚀 [SplashScreen] Navigating to: ${isCompleted ? "PhoneLogin" : "OnboardingScreen"}',
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Image.asset("assets/onbord/spalsh.png")),
    );
  }
}
