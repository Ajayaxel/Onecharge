import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserVehicle {
  final String id;
  final String name;
  final String number;
  final String? image;
  final int? vehicleTypeId;
  final int? brandId;
  final int? modelId;

  UserVehicle({
    required this.id,
    required this.name,
    required this.number,
    this.image,
    this.vehicleTypeId,
    this.brandId,
    this.modelId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'image': image,
      'vehicleTypeId': vehicleTypeId,
      'brandId': brandId,
      'modelId': modelId,
    };
  }

  factory UserVehicle.fromJson(Map<String, dynamic> json) {
    return UserVehicle(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? '',
      number: json['number'] ?? '',
      image: json['image'],
      vehicleTypeId: json['vehicleTypeId'],
      brandId: json['brandId'],
      modelId: json['modelId'],
    );
  }
}

class VehicleStorage {
  const VehicleStorage._();

  static const String _vehicleNameKey = 'selected_vehicle_name';
  static const String _vehicleNumberKey = 'selected_vehicle_number';
  static const String _vehicleImageKey = 'selected_vehicle_image';
  static const String _vehicleTypeIdKey = 'selected_vehicle_type_id';
  static const String _brandIdKey = 'selected_brand_id';
  static const String _modelIdKey = 'selected_model_id';
  static const String _allVehiclesKey = 'all_user_vehicles';

  static Future<void> saveVehicleInfo({
    required String name,
    required String number,
    String? image,
    int? vehicleTypeId,
    int? brandId,
    int? modelId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Save as selected vehicle (legacy/current support)
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

    // 2. Add to list of all vehicles if not exists (or update)
    final newVehicle = UserVehicle(
      id: DateTime.now().millisecondsSinceEpoch
          .toString(), // Simple ID generation
      name: name,
      number: number,
      image: image,
      vehicleTypeId: vehicleTypeId,
      brandId: brandId,
      modelId: modelId,
    );

    await _addOrUpdateVehicleInList(newVehicle);
  }

  static Future<void> _addOrUpdateVehicleInList(UserVehicle vehicle) async {
    final prefs = await SharedPreferences.getInstance();
    final String? vehiclesJson = prefs.getString(_allVehiclesKey);
    List<UserVehicle> vehicles = [];

    if (vehiclesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(vehiclesJson);
        vehicles = decoded.map((e) => UserVehicle.fromJson(e)).toList();
      } catch (e) {
        print('Error parsing vehicles: $e');
      }
    }

    // Check if vehicle with same number already exists, if so update it
    final index = vehicles.indexWhere((v) => v.number == vehicle.number);
    if (index != -1) {
      vehicles[index] = vehicle; // Update
    } else {
      vehicles.add(vehicle); // Add new
    }

    await prefs.setString(
      _allVehiclesKey,
      jsonEncode(vehicles.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> removeVehicle(String vehicleId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? vehiclesJson = prefs.getString(_allVehiclesKey);
    if (vehiclesJson == null) return;

    try {
      final List<dynamic> decoded = jsonDecode(vehiclesJson);
      final vehicles = decoded.map((e) => UserVehicle.fromJson(e)).toList();

      vehicles.removeWhere((v) => v.id == vehicleId);

      await prefs.setString(
        _allVehiclesKey,
        jsonEncode(vehicles.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      print('Error removing vehicle: $e');
    }
  }

  static Future<List<UserVehicle>> getAllVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? vehiclesJson = prefs.getString(_allVehiclesKey);
    if (vehiclesJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(vehiclesJson);
      return decoded.map((e) => UserVehicle.fromJson(e)).toList();
    } catch (e) {
      print('Error parsing vehicles: $e');
      return [];
    }
  }

  static Future<void> selectVehicle(UserVehicle vehicle) async {
    // Just call saveVehicleInfo with the vehicle's data to make it "selected"
    // This will also re-add/update it in the list, which is fine.
    await saveVehicleInfo(
      name: vehicle.name,
      number: vehicle.number,
      image: vehicle.image,
      vehicleTypeId: vehicle.vehicleTypeId,
      brandId: vehicle.brandId,
      modelId: vehicle.modelId,
    );
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
    // Note: We are NOT clearing the list of all vehicles here, just the selected one.
    // If we want to clear everything, we'd need a separate method.
  }
}
