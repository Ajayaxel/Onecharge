import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onecharge/const/onebtn.dart';
import 'package:onecharge/features/vehicle/data/datasources/brand_remote_data_source.dart';
import 'package:onecharge/features/vehicle/data/datasources/vehicle_category_remote_data_source.dart';
import 'package:onecharge/features/vehicle/data/models/brand.dart';
import 'package:onecharge/features/vehicle/data/models/submodel.dart';
import 'package:onecharge/features/vehicle/data/models/vehicle_category.dart';
import 'package:onecharge/features/vehicle/data/repositories/brand_repository.dart';
import 'package:onecharge/features/vehicle/data/repositories/number_plate_repository.dart';
import 'package:onecharge/features/vehicle/data/repositories/vehicle_category_repository.dart';
import 'package:onecharge/features/vehicle/presentation/bloc/brand_bloc.dart';
import 'package:onecharge/features/vehicle/presentation/bloc/model_bloc.dart';
import 'package:onecharge/features/vehicle/presentation/bloc/number_plate_bloc.dart';
import 'package:onecharge/features/vehicle/presentation/bloc/vehicle_category_bloc.dart';
import 'package:onecharge/features/vehicle/data/repositories/model_repository.dart';
import 'package:onecharge/features/vehicle/data/datasources/model_remote_data_source.dart';
import 'package:onecharge/resources/app_resources.dart';
import 'package:onecharge/screen/home/home_screen.dart';
import 'package:onecharge/screen/login/phone_login.dart';
import 'package:onecharge/core/storage/user_progress_storage.dart';
import 'package:onecharge/core/storage/vehicle_storage.dart';

class VehicleSelection extends StatefulWidget {
  const VehicleSelection({super.key});

  @override
  State<VehicleSelection> createState() => _VehicleSelectionState();
}

class _VehicleSelectionState extends State<VehicleSelection> {
  String? _selectedVehicle;
  int? _selectedCategoryId; // Track selected category ID
  bool _isDropdownOpen = false;
  Brand? _selectedBrand; // Track selected brand
  SubModel? _selectedSubModel; // Track selected sub-model
  late final VehicleCategoryBloc _vehicleCategoryBloc;
  late final BrandBloc _brandBloc;
  late final ModelBloc _modelBloc;
  late final NumberPlateBloc _numberPlateBloc;

  @override
  void initState() {
    super.initState();
    _vehicleCategoryBloc = VehicleCategoryBloc(
      VehicleCategoryRepository(
        remoteDataSource: VehicleCategoryRemoteDataSource(),
      ),
    )..add(const VehicleCategoriesFetched());

    _brandBloc = BrandBloc(
      BrandRepository(remoteDataSource: BrandRemoteDataSource()),
    );

    _modelBloc = ModelBloc(
      ModelRepository(remoteDataSource: ModelRemoteDataSource()),
    );

    _numberPlateBloc = NumberPlateBloc(NumberPlateRepository());
  }

  @override
  void dispose() {
    _vehicleCategoryBloc.close();
    _brandBloc.close();
    _modelBloc.close();
    _numberPlateBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _vehicleCategoryBloc),
        BlocProvider.value(value: _brandBloc),
        BlocProvider.value(value: _modelBloc),
        BlocProvider.value(value: _numberPlateBloc),
      ],
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
          child: BlocListener<VehicleCategoryBloc, VehicleCategoryState>(
            listener: _handleVehicleCategoryState,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button when viewing sub-models - Top aligned
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
                            Icons.arrow_back_ios_new,
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

                  if (_selectedBrand == null) const SizedBox(height: 40),

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

                  const SizedBox(height: 12),

                  // Helper text - Centered
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        "Please select your vehicle type from the dropdown below",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Custom Dropdown
                  _buildVehicleDropdown(),

                  // Show vehicle icon when no vehicle is selected
                  if (_selectedVehicle == null) ...[
                    const SizedBox(height: 40),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_car_outlined,
                              size: 120,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Choose a vehicle type to get started",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

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
        ),
        ),
      ),
    );
  }

  void _handleVehicleCategoryState(
    BuildContext context,
    VehicleCategoryState state,
  ) {
    if (!mounted) return;

    if (state is VehicleCategoryLoading ||
        state is VehicleCategoryError ||
        state is VehicleCategoryEmpty) {
      if (_isDropdownOpen) {
        setState(() {
          _isDropdownOpen = false;
        });
      }
    }

    // Auto-select "car" as default when categories are loaded and nothing is selected
    if (state is VehicleCategoryLoaded && _selectedVehicle == null) {
      final carCategory = state.categories.firstWhere(
        (category) => category.name.toLowerCase() == 'car',
        orElse: () => const VehicleCategory(id: 0, name: ''),
      );
      if (carCategory.id > 0) {
        setState(() {
          _selectedVehicle = carCategory.name;
          _selectedCategoryId = carCategory.id;
          _selectedBrand = null;
          _selectedSubModel = null;
        });
        // Fetch brands for the selected car category
        _brandBloc.add(
          BrandsFetched(
            categoryId: carCategory.id,
            categoryName: carCategory.name,
          ),
        );
      }
    }

    if (state is VehicleCategoryLoaded && _selectedVehicle != null) {
      final selectedCategory = state.categories.firstWhere(
        (category) => category.name == _selectedVehicle,
        orElse: () => const VehicleCategory(id: 0, name: ''),
      );
      if (selectedCategory.id == 0) {
        setState(() {
          _selectedVehicle = null;
          _selectedCategoryId = null;
          _selectedBrand = null;
          _selectedSubModel = null;
        });
      }
    }
  }

  Widget _buildVehicleDropdown() {
    return BlocBuilder<VehicleCategoryBloc, VehicleCategoryState>(
      builder: (context, state) {
        if (state is VehicleCategoryLoading ||
            state is VehicleCategoryInitial) {
          return _buildDropdownLoading();
        }
        if (state is VehicleCategoryError) {
          return _buildDropdownError(state.message);
        }
        if (state is VehicleCategoryEmpty) {
          return _buildDropdownError('No vehicle categories available.');
        }
        if (state is VehicleCategoryLoaded) {
          return _buildDropdownContent(state.categories);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDropdownContent(List<VehicleCategory> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              border: Border.all(color: Colors.grey.shade300, width: 1),
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
        if (_isDropdownOpen) _buildDropdownOptions(categories),
      ],
    );
  }

  Widget _buildDropdownOptions(List<VehicleCategory> categories) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 1),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Column(
            children: [
              ...List.generate(categories.length, (index) {
                final category = categories[index];
                final isLast = index == categories.length - 1;

                return Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedVehicle = category.name;
                          _selectedCategoryId = category.id;
                          _isDropdownOpen = false;
                          _selectedBrand = null;
                          _selectedSubModel = null;
                        });
                        // Fetch brands for the selected category
                        if (category.id > 0) {
                          print(
                            '🟢 [VehicleSelection] Category selected: ${category.name} (id: ${category.id})',
                          );
                          print(
                            '🟢 [VehicleSelection] Dispatching BrandsFetched event for categoryId: ${category.id}',
                          );
                          _brandBloc.add(
                            BrandsFetched(
                              categoryId: category.id,
                              categoryName: category.name,
                            ),
                          );
                        } else {
                          print(
                            '⚠️ [VehicleSelection] Category ID is 0 or invalid, not fetching brands',
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Text(
                          category.name,
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
    );
  }

  Widget _buildDropdownLoading() {
    return Container(
      width: double.infinity,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200, width: 1),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "Loading vehicles...",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownError(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade100),
            color: Colors.red.shade50,
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(fontSize: 14, color: Colors.red.shade400),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            TextButton(
              onPressed: _retryFetchCategories,
              child: const Text("Retry"),
            ),
            const SizedBox(width: 12),
            TextButton(onPressed: _navigateToLogin, child: const Text("Login")),
          ],
        ),
      ],
    );
  }

  void _retryFetchCategories() {
    _vehicleCategoryBloc.add(const VehicleCategoriesFetched());
  }

  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const PhoneLogin()),
      (route) => false,
    );
  }

  Widget _buildVehicleBrandsGrid() {
    return BlocBuilder<BrandBloc, BrandState>(
      builder: (context, state) {
        print(
          '🔵 [VehicleSelection] _buildVehicleBrandsGrid - Current state: ${state.runtimeType}',
        );

        if (state is BrandLoading || state is BrandInitial) {
          print('🟡 [VehicleSelection] Showing loading indicator');
          return const Center(child: CircularProgressIndicator());
        }
        if (state is BrandError) {
          print('❌ [VehicleSelection] BrandError state: ${state.message}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: TextStyle(fontSize: 14, color: Colors.red.shade400),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    if (_selectedCategoryId != null &&
                        (_selectedVehicle?.isNotEmpty ?? false)) {
                      print(
                        '🟢 [VehicleSelection] Retry tapped. Refetching brands for $_selectedVehicle ($_selectedCategoryId)',
                      );
                      _brandBloc.add(
                        BrandsFetched(
                          categoryId: _selectedCategoryId!,
                          categoryName: _selectedVehicle!,
                        ),
                      );
                    } else {
                      print(
                        '⚠️ [VehicleSelection] Retry tapped but category info missing. id=$_selectedCategoryId, name=$_selectedVehicle',
                      );
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (state is BrandEmpty) {
          print('🟡 [VehicleSelection] BrandEmpty state - no brands available');
          return const Center(
            child: Text(
              'No brands available for this category',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        if (state is BrandLoaded) {
          final brands = state.brands;
          print(
            '✅ [VehicleSelection] BrandLoaded state with ${brands.length} brands',
          );
          if (brands.isEmpty) {
            print('⚠️ [VehicleSelection] BrandLoaded but brands list is empty');
            return const Center(
              child: Text(
                'No brands available',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: brands.length,
            itemBuilder: (context, index) {
              final brand = brands[index];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedBrand = brand;
                    _selectedSubModel = null; // Reset sub-model selection
                  });
                  // Fetch models for the selected brand
                  print('🟢 [VehicleSelection] Brand selected: ${brand.name} (id: ${brand.id})');
                  print('🟢 [VehicleSelection] Dispatching ModelsFetched event for brandId: ${brand.id}');
                  _modelBloc.add(
                    ModelsFetched(
                      brandId: brand.id,
                      brandName: brand.name,
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: brand.logo.startsWith('http')
                        ? Image.network(
                            brand.logo,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.grey,
                                      size: 32,
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Image.asset(
                            brand.logo,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.grey,
                                      size: 32,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSubModelsView() {
    return BlocBuilder<ModelBloc, ModelState>(
      builder: (context, state) {
        if (state is ModelLoading || state is ModelInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ModelError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: TextStyle(fontSize: 14, color: Colors.red.shade400),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    if (_selectedBrand != null) {
                      _modelBloc.add(
                        ModelsFetched(
                          brandId: _selectedBrand!.id,
                          brandName: _selectedBrand!.name,
                        ),
                      );
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (state is ModelEmpty) {
          return const Center(
            child: Text(
              'No models available for this brand',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        if (state is ModelLoaded) {
          final subModels = state.models;

          if (subModels.isEmpty) {
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
        childAspectRatio: 1.0,
      ),
      itemCount: subModels.length,
      itemBuilder: (context, index) {
        final subModel = subModels[index];
        final isSelected = _selectedSubModel?.submodelId == subModel.submodelId;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSubModel = subModel;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(11),
                    ),
                    child: subModel.submodelImage.startsWith('http')
                        ? Image.network(
                            subModel.submodelImage,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          )
                        : Image.asset(
                            subModel.submodelImage,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade100,
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
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                  child: Text(
                    subModel.submodelName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
        );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAddVehicleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          if (_selectedSubModel == null) {
            _showSubModelNotSelectedDialog();
          } else {
            _showVehicleNumberBottomSheet();
          }
        },
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

  void _showSubModelNotSelectedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            "Select Sub-Model",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          content: const Text(
            "Please select a sub-model first before adding the vehicle.",
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "OK",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showVehicleNumberBottomSheet() {
    final parentContext = context;
    final scaffoldMessenger = ScaffoldMessenger.of(parentContext);
    final TextEditingController vehicleNumberController =
        TextEditingController();

    _numberPlateBloc.add(const NumberPlateReset());

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: _numberPlateBloc,
        child: Container(
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
                        text: _selectedSubModel?.submodelName ?? "vehicle",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: " registration number."),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                BlocConsumer<NumberPlateBloc, NumberPlateState>(
                  listener: (bottomSheetContext, state) async {
                    if (state.isSuccess) {
                      final vehicleName =
                          _selectedSubModel?.submodelName ?? 'My Vehicle';
                      final savedPlate =
                          state.data?.plateNumber ??
                          vehicleNumberController.text.trim();
                      final vehicleImage =
                          _selectedSubModel?.submodelImage ?? '';

                      await VehicleStorage.saveVehicleInfo(
                        name: vehicleName,
                        number: savedPlate,
                        image: vehicleImage,
                        vehicleTypeId: _selectedCategoryId,
                        brandId: _selectedBrand?.id,
                        modelId: _selectedSubModel?.submodelId,
                      );

                      Navigator.of(bottomSheetContext).pop();
                      if (mounted) {
                        _showSuccessBottomSheet();
                      }
                    } else if (state.isFailure && state.message != null) {
                      scaffoldMessenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(content: Text(state.message!)));
                    }
                  },
                  builder: (bottomSheetContext, state) {
                    return OneBtn(
                      text: "Submit",
                      isLoading: state.isLoading,
                      onPressed: () {
                        FocusScope.of(bottomSheetContext).unfocus();
                        final vehicleNumber = vehicleNumberController.text
                            .trim();
                        if (vehicleNumber.isEmpty) {
                          scaffoldMessenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter your vehicle number.',
                                ),
                              ),
                            );
                          return;
                        }

                        bottomSheetContext.read<NumberPlateBloc>().add(
                          NumberPlateSubmitted(plateNumber: vehicleNumber),
                        );
                      },
                    );
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
      ),
    );
  }

  void _showSuccessBottomSheet() {
    final parentContext = context;

    showModalBottomSheet(
      context: parentContext,
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
                onPressed: () async {
                  Navigator.of(context).pop(); // Close success sheet first
                  await UserProgressStorage.setVehicleSetupCompleted(true);
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    parentContext,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
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
