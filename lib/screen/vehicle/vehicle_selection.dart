import 'package:flutter/material.dart';
import 'package:onecharge/const/onebtn.dart';
import 'package:onecharge/resources/app_resources.dart';
import 'package:onecharge/data/vehicle_data.dart';
import 'package:onecharge/screen/home/home_screen.dart';

class VehicleSelection extends StatefulWidget {
  const VehicleSelection({super.key});

  @override
  State<VehicleSelection> createState() => _VehicleSelectionState();
}

class _VehicleSelectionState extends State<VehicleSelection> {
  String? _selectedVehicle;
  bool _isDropdownOpen = false;
  String? _selectedBrand; // Track selected brand image path
  String? _selectedSubModel; // Track selected sub-model

  final List<String> _vehicles = ['Car', 'Scooter', 'Bike'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Back button when viewing sub-models
              if (_selectedBrand != null) ...[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedBrand = null;
                      _selectedSubModel = null;
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_back,
                        color: AppColors.textColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Back",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Title - Centered
              const Center(
                child: Text(
                  "Select your vehicle",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Custom Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Select Field
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDropdownOpen = !_isDropdownOpen;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          Center(
                            child: Text(
                              _selectedVehicle ?? "Select",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedVehicle != null
                                    ? AppColors.textColor
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ),
                          Icon(
                            _isDropdownOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.grey.shade400,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Dropdown Options
                  if (_isDropdownOpen) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Column(
                        children: [
                          ...List.generate(_vehicles.length, (index) {
                            final vehicle = _vehicles[index];
                            final isLast = index == _vehicles.length - 1;

                            return Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedVehicle = vehicle;
                                      _isDropdownOpen = false;
                                      _selectedBrand =
                                          null; // Reset brand selection
                                      _selectedSubModel =
                                          null; // Reset sub-model selection
                                    });
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    child: Text(
                                      vehicle,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                ),
                                if (!isLast)
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Colors.grey.shade300,
                                  ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              // Show vehicle brand logos when a vehicle is selected and no brand is selected
              if (_selectedVehicle != null && _selectedBrand == null) ...[
                const SizedBox(height: 30),
                Expanded(child: _buildVehicleBrandsGrid()),
              ],

              // Show sub-models when a brand is selected
              if (_selectedBrand != null) ...[
                const SizedBox(height: 30),
                Expanded(child: _buildSubModelsView()),
                const SizedBox(height: 20),
                _buildAddVehicleButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleBrandsGrid() {
    final images = VehicleData.getImagesByName(_selectedVehicle!);

    if (images == null || images.isEmpty) {
      return const SizedBox.shrink();
    }

    // Debug: Print image paths
    debugPrint('Loading images for $_selectedVehicle: $images');

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final imagePath = images[index];
        debugPrint('Loading image at index $index: $imagePath');

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedBrand = imagePath;
              _selectedSubModel = null; // Reset sub-model selection
            });
          },

          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          imagePath.split('/').last,
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubModelsView() {
    final subModels = VehicleData.getSubModelsByBrand(_selectedBrand!);

    if (subModels == null || subModels.isEmpty) {
      return const Center(
        child: Text(
          "No sub-models available for this brand",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: subModels.length,
      itemBuilder: (context, index) {
        final subModel = subModels[index];
        final isSelected = _selectedSubModel == subModel.name;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSubModel = subModel.name;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.white,
                width: isSelected ? 2 : 1,
              ),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Image.asset(
                  subModel.imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
                Text(
                  subModel.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddVehicleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _selectedSubModel != null
            ? () {
                _showVehicleNumberBottomSheet();
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: const Text(
          "Add Vehicle",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                  color: AppColors.textColor,
                ),
              ),

              const SizedBox(height: 20),

              // Vehicle Number Input Field
              TextField(
                controller: vehicleNumberController,
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

              // Prompt text with selected model name
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textColor,
                  ),
                  children: [
                    const TextSpan(text: "Enter your "),
                    TextSpan(
                      text: _selectedSubModel ?? "vehicle",
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
                  if (vehicleNumber.isNotEmpty) {
                    // Handle submit action
                    debugPrint(
                      'Vehicle Number: $vehicleNumber for $_selectedSubModel',
                    );
                    Navigator.pop(
                      context,
                    ); // Close the vehicle number input bottom sheet
                    _showSuccessBottomSheet(); // Show success bottom sheet
                  }
                },
              ),

              const SizedBox(height: 16),

              // Bottom message
              const Center(
                child: Text(
                  "Just once! Register your vehicle now, and we'll remember it for you.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textColor),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessBottomSheet() {
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
                  color: AppColors.textColor,
                ),
              ),

              const SizedBox(height: 12),

              // Success message
              const Text(
                "Vehicle number successfully added!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textColor),
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
                onPressed: () {
               
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
