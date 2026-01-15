

import 'package:flutter/material.dart';
import 'package:onecharge/const/onebtn.dart';
import 'package:onecharge/screen/home/home_screen.dart';
import 'package:onecharge/core/storage/vehicle_storage.dart';

class VehicleSelection extends StatefulWidget {
  const VehicleSelection({super.key});

  @override
  State<VehicleSelection> createState() => _VehicleSelectionState();
}

class _VehicleSelectionState extends State<VehicleSelection> {
  String? selectedBrand = 'Tesla';
  String selectedVehicleType = 'Sedan';
  Map<String, String>? selectedVehicle; // Track selected vehicle
  final TextEditingController searchController = TextEditingController();

  // Sample brand data - Replace with your actual brand data
  final List<Map<String, String>> brands = [
    {'name': 'Tesla', 'logo': 'assets/vehicle/Tesla.png'},
    {'name': 'BMW', 'logo': 'assets/vehicle/Bmw.png'},
    {'name': 'BYD', 'logo': 'assets/vehicle/BYD auto logo.png'},
    {'name': 'Volkswagen', 'logo': 'assets/vehicle/Volkswagen.png'},
  ];

  final List<String> vehicleTypes = ['Sedan', 'SUV'];

  // Sample vehicle data for Sedan - Replace with your actual vehicle data
  final List<Map<String, String>> sedanVehicles = [
    {
      'name': 'Tesla Model S',
      'image': 'assets/vehicle/teslamodel1.png',
      'brand': 'Tesla',
      'category': 'Sedan',
    },
    {
      'name': 'Tesla Model 3',
      'image': 'assets/vehicle/modelx.png',
      'brand': 'Tesla',
      'category': 'Sedan',
    },
    {
      'name': 'Tesla Model Y',
      'image': 'assets/vehicle/teslamodely.png',
      'brand': 'Tesla',
      'category': 'SUV',
    },
    {
      'name': 'Tesla Model S',
      'image': 'assets/vehicle/modelxtestla.png',
      'brand': 'Tesla',
      'category': 'Sedan',
    },
    {
      'name': 'BMW i7 Model',
      'image': 'assets/vehicle/bmwI7.png',
      'brand': 'BMW',
      'category': 'Sedan',
    },
    {
      'name': 'BMW i7 M Model',
      'image': 'assets/vehicle/bmwi7m.png',
      'brand': 'BMW',
      'category': 'Sedan',
    },
    {
      'name': 'BMW i5 M Model',
      'image': 'assets/vehicle/bmwI5.png',
      'brand': 'BMW',
      'category': 'Sedan',
    },
    {
      'name': 'BYD Han',
      'image': 'assets/vehicle/modelxtestla.png',
      'brand': 'BYD',
      'category': 'Sedan',
    },
    {
      'name': 'BYD Seal',
      'image': 'assets/vehicle/teslamodely.png',
      'brand': 'BYD',
      'category': 'Sedan',
    },
    {
      'name': 'VW ID.7',
      'image': 'assets/vehicle/modelx.png',
      'brand': 'Volkswagen',
      'category': 'Sedan',
    },
  ];

  // Sample vehicle data for SUV - Replace with your actual vehicle data
  final List<Map<String, String>> suvVehicles = [
    {
      'name': 'Cyber Truck',
      'image': 'assets/vehicle/suv.png',
      'brand': 'Tesla',
      'category': 'SUV',
    },

    {
      'name': 'BMW iX',
      'image': 'assets/vehicle/modelx.png',
      'brand': 'BMW',
      'category': 'SUV',
    },
    {
      'name': 'BMW X5',
      'image': 'assets/vehicle/teslamodel1.png',
      'brand': 'BMW',
      'category': 'SUV',
    },
    {
      'name': 'BYD Tang',
      'image': 'assets/vehicle/modelxtestla.png',
      'brand': 'BYD',
      'category': 'SUV',
    },
    {
      'name': 'VW ID.4',
      'image': 'assets/vehicle/teslamodely.png',
      'brand': 'Volkswagen',
      'category': 'SUV',
    },
  ];

  // Get filtered vehicles based on selected category, brand, and search query
  List<Map<String, String>> get filteredVehicles {
    List<Map<String, String>> vehicles = selectedVehicleType == 'Sedan'
        ? sedanVehicles
        : suvVehicles;

    // Filter by brand if a brand is selected
    if (selectedBrand != null) {
      vehicles = vehicles
          .where((vehicle) => vehicle['brand'] == selectedBrand)
          .toList();
    }

    // Filter by search query
    final searchQuery = searchController.text.trim().toLowerCase();
    if (searchQuery.isNotEmpty) {
      vehicles = vehicles
          .where(
            (vehicle) => vehicle['name']!.toLowerCase().contains(searchQuery),
          )
          .toList();
    }

    return vehicles;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Center(
                        child: Text(
                          "Select your vehicle",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Search Bar
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: searchController,
                          onChanged: (value) {
                            setState(() {
                              // Trigger rebuild to update filtered vehicles
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search Vehicles',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey.shade600,
                              size: 24,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Brands Label
                      const Text(
                        'Brands',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Brand Grid
                      SizedBox(
                        height: 110,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 8,
                                mainAxisExtent: 110,
                              ),
                          itemCount: brands.length,
                          itemBuilder: (context, index) {
                            final brand = brands[index];
                            final isSelected = selectedBrand == brand['name'];

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedBrand = brand['name'];
                                });
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Brand Logo Avatar
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Container(
                                      width: 77,
                                      height: 77,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFF5F5F5),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Image.asset(
                                          brand['logo']!,
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                // Fallback to icon if image not found
                                                return Icon(
                                                  Icons.directions_car,
                                                  size: 40,
                                                  color: Colors.grey.shade400,
                                                );
                                              },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),

                                  // Brand Name
                                  Text(
                                    brand['name']!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Vehicles Label
                      const Text(
                        "Vehicles",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Vehicle Type Filters
                      Row(
                        children: vehicleTypes.map((type) {
                          final isSelected = selectedVehicleType == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedVehicleType = type;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.black
                                        : const Color(0xFFE0E0E0),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      type == 'Sedan'
                                          ? Icons.directions_car
                                          : Icons.directions_car,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      type,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Vehicle List with Smooth Animation
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position:
                                      Tween<Offset>(
                                        begin: const Offset(0.0, 0.1),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutCubic,
                                        ),
                                      ),
                                  child: child,
                                ),
                              );
                            },
                        child: Column(
                          key: ValueKey<String>(selectedVehicleType),
                          children: filteredVehicles.map((vehicle) {
                            final isSelected = selectedVehicle == vehicle;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedVehicle = vehicle;
                                  });
                                  _showVehicleNumberBottomSheet();
                                },
                                child: Container(
                                  height: 141,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      // Vehicle Name
                                      Positioned(
                                        left: 20,
                                        top: 20,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              vehicle['name']!.split(' ')[0],
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black,
                                              ),
                                            ),
                                            Text(
                                              vehicle['name']!
                                                  .split(' ')
                                                  .sublist(1)
                                                  .join(' '),
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Vehicle Image
                                      Positioned(
                                        right: 0,
                                        bottom: 5,
                                        top: 5,
                                        child: Image.asset(
                                          vehicle['image']!,
                                          fit: BoxFit.contain,
                                          height: 142,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                // Fallback to icon if image not found
                                                return Center(
                                                  child: Icon(
                                                    Icons.directions_car,
                                                    size: 80,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVehicleNumberBottomSheet() {
    final TextEditingController vehicleNumberController =
        TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                const Text(
                  "Enter your Vehicle Number",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 20),

                // Vehicle Number Input Field
                TextField(
                  controller: vehicleNumberController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: "Vehicle Number",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Prompt text with selected vehicle name
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    children: [
                      const TextSpan(text: "Enter your "),
                      TextSpan(
                        text: selectedVehicle?['name'] ?? "vehicle",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: " registration number."),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                OneBtn(
                  text: "Submit",
                  onPressed: () {
                    final vehicleNumber = vehicleNumberController.text.trim();
                    if (vehicleNumber.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter your vehicle number.'),
                        ),
                      );
                      return;
                    }

                    // Close the bottom sheet and show success
                    Navigator.of(context).pop();
                    _showSuccessBottomSheet(vehicleNumber);
                  },
                ),

                const SizedBox(height: 16),

                // Bottom message
                const Center(
                  child: Text(
                    "Just once! Register your vehicle now, and we'll remember it for you.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessBottomSheet(String vehicleNumber) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                const Text(
                  "Congratulations!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 12),

                // Success message
                const Text(
                  "Vehicle number successfully added!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),

                const SizedBox(height: 24),

                // Green checkmark icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 50),
                ),

                const SizedBox(height: 32),

                // Continue Button
                OneBtn(
                  text: "Continue",
                  onPressed: () async {
                    Navigator.of(context).pop(); // Close success sheet

                    // Save vehicle info to storage
                    await VehicleStorage.saveVehicleInfo(
                      name: selectedVehicle?['name'] ?? 'My Vehicle',
                      number: vehicleNumber,
                      image: selectedVehicle?['image'],
                    );

                    // Navigate to HomeScreen and remove all previous routes
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
