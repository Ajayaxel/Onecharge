import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:onecharge/const/onebtn.dart';
import 'package:onecharge/core/storage/token_storage.dart';
import 'package:onecharge/features/issue_report/presentation/bloc/issue_report_bloc.dart';
import 'package:onecharge/features/issue_report/data/models/issue_category.dart';
import 'package:onecharge/features/issue_report/data/models/vehicle_type.dart';
import 'package:onecharge/features/issue_report/data/models/brand_model.dart';
import 'package:onecharge/features/issue_report/data/models/model_item.dart';
import 'package:onecharge/features/issue_report/data/repositories/issue_report_repository.dart';
import 'package:onecharge/resources/app_resources.dart';
import 'package:onecharge/screen/issue_report/success_screen.dart';
import 'package:onecharge/screen/issue_report/location_selection_screen.dart';
import 'package:onecharge/screen/login/phone_login.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberPlateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  // Dropdown values
  IssueCategory? _selectedIssueCategory;
  VehicleType? _selectedVehicleType;
  BrandModel? _selectedBrand;
  ModelItem? _selectedModel;

  // Dropdown data
  List<IssueCategory> _issueCategories = [];
  List<VehicleType> _vehicleTypes = [];
  List<BrandModel> _brands = [];
  List<ModelItem> _models = [];

  // Loading states
  bool _isLoadingCategories = false;
  bool _isLoadingVehicleTypes = false;
  bool _isLoadingBrands = false;
  bool _isLoadingModels = false;

  // Error messages
  String? _categoryError;
  String? _vehicleTypeError;
  String? _brandError;
  String? _modelError;
  String? _numberPlateError;

  // Selected files
  List<String> _selectedFiles = [];

  // Location
  double? _selectedLatitude;
  double? _selectedLongitude;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_fetchIssueCategories(), _fetchVehicleTypes()]);
  }

  Future<void> _fetchIssueCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      final repository = IssueReportRepository();
      final categories = await repository.fetchIssueCategories();
      setState(() {
        _issueCategories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
        _categoryError = e.toString();
      });
    }
  }

  Future<void> _fetchVehicleTypes() async {
    setState(() {
      _isLoadingVehicleTypes = true;
      _vehicleTypeError = null;
    });

    try {
      final repository = IssueReportRepository();
      final types = await repository.getVehicleTypes();
      setState(() {
        _vehicleTypes = types;
        _isLoadingVehicleTypes = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingVehicleTypes = false;
        _vehicleTypeError = e.toString();
      });
    }
  }

  Future<void> _fetchBrands(int vehicleTypeId) async {
    setState(() {
      _isLoadingBrands = true;
      _brandError = null;
      _brands = [];
      _selectedBrand = null;
      _models = [];
      _selectedModel = null;
    });

    try {
      final repository = IssueReportRepository();
      final brands = await repository.getBrands(vehicleTypeId);
      setState(() {
        _brands = brands;
        _isLoadingBrands = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBrands = false;
        _brandError = e.toString();
      });
    }
  }

  Future<void> _fetchModels(int brandId) async {
    setState(() {
      _isLoadingModels = true;
      _modelError = null;
      _models = [];
      _selectedModel = null;
    });

    try {
      final repository = IssueReportRepository();
      final models = await repository.getModels(brandId);
      setState(() {
        _models = models;
        _isLoadingModels = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingModels = false;
        _modelError = e.toString();
      });
    }
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (context) => const LocationSelectionScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLatitude = result['latitude'] as double;
        _selectedLongitude = result['longitude'] as double;
        _locationController.text = result['address'] as String;
        _latitudeController.text = _selectedLatitude!.toStringAsFixed(6);
        _longitudeController.text = _selectedLongitude!.toStringAsFixed(6);
      });
    }
  }

  Future<bool> _requestPhotoPermission() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.status;
      if (status.isDenied) {
        final result = await Permission.photos.request();
        if (result.isDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Photo library permission is required to select photos.',
                ),
              ),
            );
          }
          return false;
        }
      }
      if (status.isPermanentlyDenied) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                'Photo library permission is required. Please enable it in Settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
        return false;
      }
    } else if (Platform.isAndroid) {
      // On Android 13+, image_picker uses the system photo picker which doesn't require permissions.
      // For older versions, image_picker handles permissions internally as needed.
      return true;
    }
    return true;
  }

  Future<void> _pickFiles() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose Photos from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _pickMultipleImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Choose Videos from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _pickMultipleVideos();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMultipleImages() async {
    // Request photo permission first
    final hasPermission = await _requestPhotoPermission();
    if (!hasPermission) {
      return;
    }

    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );
      if (images.isNotEmpty && mounted) {
        setState(() {
          _selectedFiles.addAll(images.map((img) => img.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickMultipleVideos() async {
    // Request photo permission first
    final hasPermission = await _requestPhotoPermission();
    if (!hasPermission) {
      return;
    }

    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null && mounted) {
        setState(() {
          _selectedFiles.add(video.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking video: ${e.toString()}')),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  bool _isVideoFile(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.mp4') ||
        lowerPath.endsWith('.mov') ||
        lowerPath.endsWith('.avi') ||
        lowerPath.endsWith('.mkv');
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '${minutes}m';
      }
      return '${minutes}m ${remainingSeconds}s';
    }
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    // Clear previous errors
    setState(() {
      _numberPlateError = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required fields
    if (_selectedIssueCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an issue category')),
      );
      return;
    }

    if (_selectedVehicleType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle type')),
      );
      return;
    }

    if (_selectedBrand == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a brand')));
      return;
    }

    if (_selectedModel == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a model')));
      return;
    }

    // Validate number plate is not empty
    final numberPlate = _numberPlateController.text.trim();
    if (numberPlate.isEmpty) {
      setState(() {
        _numberPlateError = 'Number plate is required';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a number plate')),
      );
      return;
    }

    // Validate description if issue category is 6 (Other)
    if (_selectedIssueCategory!.id == 6) {
      if (_descriptionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Description is required for this issue category'),
          ),
        );
        return;
      }
    }

    // Validate location
    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a location')));
      return;
    }

    // Submit ticket
    context.read<IssueReportBloc>().add(
      CreateTicketSubmitted(
        issueCategoryId: _selectedIssueCategory!.id,
        vehicleTypeId: _selectedVehicleType!.id,
        brandId: _selectedBrand!.id,
        modelId: _selectedModel!.id,
        numberPlate: numberPlate,
        location: _locationController.text.trim(),
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        mediaPaths: _selectedFiles.isNotEmpty ? _selectedFiles : null,
      ),
    );
  }

  @override
  void dispose() {
    _numberPlateController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textColor,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Create Ticket',
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocListener<IssueReportBloc, IssueReportState>(
          listener: (context, state) {
            if (state.isSuccess) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => SuccessScreen(
                    isSuccess: true,
                    message: state.message ?? 'Ticket created successfully',
                    ticket: state.ticket,
                  ),
                ),
              );
            } else if (state.isFailure) {
              if (state.statusCode == 401) {
                TokenStorage.clearToken().then((_) {
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PhoneLogin(),
                      ),
                      (route) => false,
                    );
                  }
                });
              } else if (state.statusCode == 422 ||
                  (state.errors != null && state.errors!.isNotEmpty)) {
                // Validation errors - show on form
                setState(() {
                  // Set field-specific errors
                  if (state.errors != null) {
                    if (state.errors!.containsKey('number_plate')) {
                      _numberPlateError =
                          state.errors!['number_plate']?.join(', ') ?? '';
                    }
                    if (state.errors!.containsKey('description')) {
                      // Description error will be shown via form validation
                    }
                  }
                });

                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message ?? 'Please fix the errors and try again',
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              } else {
                // Navigate to error screen for other errors
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => SuccessScreen(
                      isSuccess: false,
                      message: state.message ?? 'Something went wrong',
                    ),
                  ),
                );
              }
            }
          },
          child: BlocBuilder<IssueReportBloc, IssueReportState>(
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Issue Category Dropdown
                      const Text(
                        'Issue Category *',
                        style: TextStyle(
                          color: AppColors.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDropdown<IssueCategory>(
                        value: _selectedIssueCategory,
                        items: _issueCategories,
                        isLoading: _isLoadingCategories,
                        error: _categoryError,
                        onChanged: (category) {
                          setState(() {
                            _selectedIssueCategory = category;
                            if (category?.id != 6) {
                              _descriptionController.clear();
                            }
                          });
                        },
                        getLabel: (category) => category.name,
                        hint: 'Select issue category',
                        onRetry: _fetchIssueCategories,
                      ),
                      const SizedBox(height: 16),

                      // Description (shown only when category ID is 6)
                      if (_selectedIssueCategory?.id == 6) ...[
                        const Text(
                          'Description *',
                          style: TextStyle(
                            color: AppColors.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            hintText: 'Describe your issue',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          maxLines: 4,
                          validator: (value) {
                            if (_selectedIssueCategory?.id == 6 &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Description is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Vehicle Type Dropdown
                      const Text(
                        'Vehicle Type *',
                        style: TextStyle(
                          color: AppColors.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDropdown<VehicleType>(
                        value: _selectedVehicleType,
                        items: _vehicleTypes,
                        isLoading: _isLoadingVehicleTypes,
                        error: _vehicleTypeError,
                        onChanged: (type) {
                          setState(() {
                            _selectedVehicleType = type;
                            _selectedBrand = null;
                            _selectedModel = null;
                            _brands = [];
                            _models = [];
                          });
                          if (type != null) {
                            _fetchBrands(type.id);
                          }
                        },
                        getLabel: (type) => type.name,
                        hint: 'Select vehicle type',
                        onRetry: _fetchVehicleTypes,
                      ),
                      const SizedBox(height: 16),

                      // Brand Dropdown
                      const Text(
                        'Brand *',
                        style: TextStyle(
                          color: AppColors.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDropdown<BrandModel>(
                        value: _selectedBrand,
                        items: _brands,
                        isLoading: _isLoadingBrands,
                        error: _brandError,
                        enabled: _selectedVehicleType != null,
                        onChanged: (brand) {
                          setState(() {
                            _selectedBrand = brand;
                            _selectedModel = null;
                            _models = [];
                          });
                          if (brand != null) {
                            _fetchModels(brand.id);
                          }
                        },
                        getLabel: (brand) => brand.name,
                        hint: _selectedVehicleType == null
                            ? 'Select vehicle type first'
                            : 'Select brand',
                        onRetry: _selectedVehicleType != null
                            ? () => _fetchBrands(_selectedVehicleType!.id)
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Model Dropdown
                      const Text(
                        'Model *',
                        style: TextStyle(
                          color: AppColors.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDropdown<ModelItem>(
                        value: _selectedModel,
                        items: _models,
                        isLoading: _isLoadingModels,
                        error: _modelError,
                        enabled: _selectedBrand != null,
                        onChanged: (model) {
                          setState(() {
                            _selectedModel = model;
                          });
                        },
                        getLabel: (model) => model.name,
                        hint: _selectedBrand == null
                            ? 'Select brand first'
                            : 'Select model',
                        onRetry: _selectedBrand != null
                            ? () => _fetchModels(_selectedBrand!.id)
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Number Plate
                      const Text(
                        'Number Plate *',
                        style: TextStyle(
                          color: AppColors.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _numberPlateController,
                        decoration: InputDecoration(
                          hintText: 'Enter vehicle number plate',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          errorText: _numberPlateError,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Number plate is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Location
                      const Text(
                        'Location *',
                        style: TextStyle(
                          color: AppColors.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _locationController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Tap to select location',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          suffixIcon: const Icon(Icons.location_on),
                        ),
                        onTap: _selectLocation,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Location is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Latitude/Longitude (Optional)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudeController,
                              decoration: InputDecoration(
                                labelText: 'Latitude (Optional)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _longitudeController,
                              decoration: InputDecoration(
                                labelText: 'Longitude (Optional)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // File Upload Section
                      const Text(
                        'Attachments (Optional)',
                        style: TextStyle(
                          color: AppColors.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedFiles.isEmpty)
                        _buildUploadButton()
                      else
                        _buildFilesList(),
                      const SizedBox(height: 24),

                      // Upload Progress Indicator
                      if (state.isUploading &&
                          state.uploadProgress != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Uploading files...',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${state.currentUploadingFile ?? 0}/${state.totalFiles ?? 0}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (state.currentFileName != null)
                                    Expanded(
                                      child: Text(
                                        'Current: ${state.currentFileName}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  if (state.elapsedSeconds != null) ...[
                                    if (state.currentFileName != null)
                                      const SizedBox(width: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.blue.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDuration(
                                            state.elapsedSeconds!,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Overall progress
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Overall Progress',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      Text(
                                        '${((state.uploadProgress ?? 0) * 100).toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: state.uploadProgress,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryColor,
                                    ),
                                    minHeight: 8,
                                  ),
                                ],
                              ),
                              // Current file progress (if available)
                              if (state.currentFileProgress != null &&
                                  state.currentFileProgress! > 0 &&
                                  state.currentFileProgress! < 1) ...[
                                const SizedBox(height: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Current File',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        Text(
                                          '${(state.currentFileProgress! * 100).toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: state.currentFileProgress,
                                      backgroundColor: Colors.grey.shade300,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue,
                                      ),
                                      minHeight: 6,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Submit Button
                      OneBtn(
                        text: state.isLoading
                            ? (state.isUploading
                                  ? 'Uploading...'
                                  : 'Creating...')
                            : 'Create Ticket',
                        onPressed: state.isLoading ? null : _handleSubmit,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required bool isLoading,
    String? error,
    required Function(T?) onChanged,
    required String Function(T) getLabel,
    required String hint,
    bool enabled = true,
    VoidCallback? onRetry,
  }) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Loading...'),
          ],
        ),
      );
    }

    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Error: $error', style: const TextStyle(color: Colors.red)),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      );
    }

    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<T>(value: item, child: Text(getLabel(item)));
      }).toList(),
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade200,
      ),
    );
  }

  Widget _buildUploadButton() {
    return GestureDetector(
      onTap: _pickFiles,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_photo_alternate,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add photos or videos',
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemCount: _selectedFiles.length + 1, // +1 for add button
          itemBuilder: (context, index) {
            if (index == _selectedFiles.length) {
              return GestureDetector(
                onTap: _pickFiles,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.add, size: 32),
                ),
              );
            }
            return _buildFileItem(_selectedFiles[index], index);
          },
        ),
      ],
    );
  }

  Widget _buildFileItem(String filePath, int index) {
    final isVideo = _isVideoFile(filePath);
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isVideo
              ? Container(
                  color: Colors.black,
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                )
              : Image.file(
                  File(filePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, size: 32),
                    );
                  },
                ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeFile(index),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
        if (isVideo)
          const Positioned(
            bottom: 4,
            left: 4,
            child: Icon(Icons.videocam, color: Colors.white, size: 16),
          ),
      ],
    );
  }
}
