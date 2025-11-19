import 'package:shared_preferences/shared_preferences.dart';

class VehicleStorage {
  const VehicleStorage._();

  static const String _vehicleNameKey = 'selected_vehicle_name';
  static const String _vehicleNumberKey = 'selected_vehicle_number';
  static const String _vehicleImageKey = 'selected_vehicle_image';

  static Future<void> saveVehicleInfo({
    required String name,
    required String number,
    String? image,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vehicleNameKey, name);
    await prefs.setString(_vehicleNumberKey, number);
    if (image != null && image.isNotEmpty) {
      await prefs.setString(_vehicleImageKey, image);
    } else {
      await prefs.remove(_vehicleImageKey);
    }
  }

  static Future<String?> getVehicleName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_vehicleNameKey);
  }

  static Future<String?> getVehicleNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_vehicleNumberKey);
  }

  static Future<String?> getVehicleImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_vehicleImageKey);
  }

  static Future<void> clearVehicleInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vehicleNameKey);
    await prefs.remove(_vehicleNumberKey);
    await prefs.remove(_vehicleImageKey);
  }
}
