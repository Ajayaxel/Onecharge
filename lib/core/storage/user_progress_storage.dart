import 'package:shared_preferences/shared_preferences.dart';

class UserProgressStorage {
  const UserProgressStorage._();

  static const String _vehicleSetupKey = 'vehicle_setup_completed';

  static Future<void> setVehicleSetupCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vehicleSetupKey, value);
  }

  static Future<bool> isVehicleSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vehicleSetupKey) ?? false;
  }

  static Future<void> clearVehicleSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vehicleSetupKey);
  }
}
