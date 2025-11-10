class VehicleSubModel {
  final String name;
  final String imagePath;
  final String? subText;

  const VehicleSubModel({
    required this.name,
    required this.imagePath,
    this.subText,
  });
}

class VehicleData {
  // List of vehicle names
  static const List<String> vehicles = ['Car', 'Scooter', 'Bike'];
  

  static const Map<String, List<String>> vehicleImages = {
    "Car": [
      "assets/vehicle/tesla.png",
      "assets/vehicle/bmw.png",
      "assets/vehicle/byd.png",
      "assets/vehicle/w.png",
    ],
    "Scooter": [
      "assets/vehicle/images.png",
      "assets/vehicle/images.png",
    ],
    "Bike": [
      "assets/vehicle/bmw.png",
      "assets/vehicle/byd.png",
    ],
  };

  // Map brand image paths to their sub-models
  static const Map<String, List<VehicleSubModel>> brandSubModels = {
    "assets/vehicle/tesla.png": [
      VehicleSubModel(
        name: "Tesla Model S",
        imagePath: "assets/vehicle/tesalimage1.png",
        subText: "Sedan",
      ),
      VehicleSubModel(
        name: "Tesla Model X",
        imagePath: "assets/vehicle/teslaimage2.png",
        subText: "SUV",
      ),
    ],
  };
  
  // Helper method to get all images by vehicle name
  static List<String>? getImagesByName(String vehicleName) {
    return vehicleImages[vehicleName];
  }
  
  // Helper method to get a single image by vehicle name and index
  static String? getImageByName(String vehicleName, int index) {
    final images = vehicleImages[vehicleName];
    if (images != null && index >= 0 && index < images.length) {
      return images[index];
    }
    return null;
  }

  // Helper method to get sub-models by brand image path
  static List<VehicleSubModel>? getSubModelsByBrand(String brandImagePath) {
    return brandSubModels[brandImagePath];
  }
}
