import 'package:flutter/material.dart';
import 'package:onecharge/const/onebtn.dart';
import 'package:onecharge/core/storage/vehicle_storage.dart';
import 'package:onecharge/resources/app_resources.dart';
import 'package:onecharge/screen/vehicle/vehicle_selection.dart';

class VehicleManagementDialog extends StatefulWidget {
  final String vehicleName;
  final String vehicleNumber;
  final String? vehicleImage;
  final VoidCallback onUpdate;

  const VehicleManagementDialog({
    super.key,
    required this.vehicleName,
    required this.vehicleNumber,
    this.vehicleImage,
    required this.onUpdate,
  });

  @override
  State<VehicleManagementDialog> createState() =>
      _VehicleManagementDialogState();
}

class _VehicleManagementDialogState extends State<VehicleManagementDialog> {
  late TextEditingController _numberController;
  bool _isEditing = false;
  List<UserVehicle> _allVehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(text: widget.vehicleNumber);
    _loadAllVehicles();
  }

  Future<void> _loadAllVehicles() async {
    final vehicles = await VehicleStorage.getAllVehicles();
    if (mounted) {
      setState(() {
        _allVehicles = vehicles;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicleNumber() async {
    final newNumber = _numberController.text.trim();
    if (newNumber.isNotEmpty) {
      final typeId = await VehicleStorage.getVehicleTypeId();
      final brandId = await VehicleStorage.getBrandId();
      final modelId = await VehicleStorage.getModelId();
      final image = await VehicleStorage.getVehicleImage();
      final name = await VehicleStorage.getVehicleName();

      await VehicleStorage.saveVehicleInfo(
        name: name ?? widget.vehicleName,
        number: newNumber,
        image: image,
        vehicleTypeId: typeId,
        brandId: brandId,
        modelId: modelId,
      );

      widget.onUpdate();
      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        _loadAllVehicles(); // Reload list to reflect changes
      }
    }
  }

  Future<void> _selectVehicle(UserVehicle vehicle) async {
    await VehicleStorage.selectVehicle(vehicle);
    widget.onUpdate();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteVehicle(UserVehicle vehicle) async {
    await VehicleStorage.removeVehicle(vehicle.id);
    _loadAllVehicles();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Vehicles',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Current Vehicle Card (Editable)
              _buildCurrentVehicleCard(),

              const SizedBox(height: 24),

              // List of other vehicles
              if (_allVehicles.length > 1) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Switch Vehicle",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double itemWidth =
                        (constraints.maxWidth - (12 * 3)) / 4;
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _allVehicles
                            .where((v) => v.number != widget.vehicleNumber)
                            .map((vehicle) {
                              return InkWell(
                                onTap: () => _selectVehicle(vehicle),
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: itemWidth,
                                      height: itemWidth / 0.8,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                4.0,
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child:
                                                    vehicle.image != null &&
                                                        vehicle.image!
                                                            .startsWith('http')
                                                    ? Image.network(
                                                        vehicle.image!,
                                                        fit: BoxFit.contain,
                                                        errorBuilder:
                                                            (
                                                              _,
                                                              __,
                                                              ___,
                                                            ) => const Icon(
                                                              Icons
                                                                  .electric_car,
                                                              size: 24,
                                                            ),
                                                      )
                                                    : Image.asset(
                                                        vehicle.image ??
                                                            'assets/vehicle/tesla.png',
                                                        fit: BoxFit.contain,
                                                        errorBuilder:
                                                            (
                                                              _,
                                                              __,
                                                              ___,
                                                            ) => const Icon(
                                                              Icons
                                                                  .electric_car,
                                                              size: 24,
                                                            ),
                                                      ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8.0,
                                              left: 4,
                                              right: 4,
                                            ),
                                            child: Text(
                                              vehicle.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: InkWell(
                                        onTap: () => _deleteVehicle(vehicle),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            })
                            .toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Add Vehicle Button
              OneBtn(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VehicleSelection(),
                    ),
                  );
                },
                text: 'Add Another Vehicle',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentVehicleCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (widget.vehicleImage != null && widget.vehicleImage!.isNotEmpty)
            Container(
              height: 100,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.vehicleImage!.startsWith('http')
                    ? Image.network(
                        widget.vehicleImage!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.electric_car,
                          size: 80,
                          color: Colors.grey,
                        ),
                      )
                    : Image.asset(
                        widget.vehicleImage!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.electric_car,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Icon(Icons.electric_car, size: 100, color: Colors.grey),
            ),

          Text(
            widget.vehicleName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          if (_isEditing)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _numberController,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: 'Vehicle Number',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _saveVehicleNumber,
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    widget.vehicleNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade100,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
