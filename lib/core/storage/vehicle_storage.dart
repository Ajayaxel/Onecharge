import 'package:shared_preferences/shared_preferences.dart';

class VehicleStorage {
  const VehicleStorage._();

  static const String _vehicleNameKey = 'selected_vehicle_name';
  static const String _vehicleNumberKey = 'selected_vehicle_number';
  static const String _vehicleImageKey = 'selected_vehicle_image';
  static const String _vehicleTypeIdKey = 'selected_vehicle_type_id';
  static const String _brandIdKey = 'selected_brand_id';
  static const String _modelIdKey = 'selected_model_id';

  static Future<void> saveVehicleInfo({
    required String name,
    required String number,
    String? image,
    int? vehicleTypeId,
    int? brandId,
    int? modelId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vehicleNameKey, name);
    await prefs.setString(_vehicleNumberKey, number);
    if (image != null && image.isNotEmpty) {
      await prefs.setString(_vehicleImageKey, image);
    } else {
      await prefs.remove(_vehicleImageKey);
    }
    if (vehicleTypeId != null) {
      await prefs.setInt(_vehicleTypeIdKey, vehicleTypeId);
    } else {
      await prefs.remove(_vehicleTypeIdKey);
    }
    if (brandId != null) {
      await prefs.setInt(_brandIdKey, brandId);
    } else {
      await prefs.remove(_brandIdKey);
    }
    if (modelId != null) {
      await prefs.setInt(_modelIdKey, modelId);
    } else {
      await prefs.remove(_modelIdKey);
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

  static Future<int?> getVehicleTypeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_vehicleTypeIdKey);
  }

  static Future<int?> getBrandId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_brandIdKey);
  }

  static Future<int?> getModelId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_modelIdKey);
  }

  static Future<void> clearVehicleInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vehicleNameKey);
    await prefs.remove(_vehicleNumberKey);
    await prefs.remove(_vehicleImageKey);
    await prefs.remove(_vehicleTypeIdKey);
    await prefs.remove(_brandIdKey);
    await prefs.remove(_modelIdKey);
  }
}
