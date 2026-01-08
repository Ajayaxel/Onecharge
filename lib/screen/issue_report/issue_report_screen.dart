import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:lottie/lottie.dart';
import 'package:onecharge/const/onebtn.dart';
import 'package:onecharge/core/storage/token_storage.dart';
import 'package:onecharge/core/storage/vehicle_storage.dart';
import 'package:onecharge/features/issue_report/presentation/bloc/issue_report_bloc.dart';
import 'package:onecharge/features/issue_report/data/models/issue_category.dart';
import 'package:onecharge/features/issue_report/data/repositories/issue_report_repository.dart';
import 'package:onecharge/resources/app_resources.dart';
import 'package:onecharge/screen/issue_report/success_screen.dart';
import 'package:onecharge/screen/issue_report/location_selection_screen.dart';
import 'package:onecharge/screen/login/phone_login.dart';
import 'package:onecharge/screen/payment/payment_webview_screen.dart';

class IssueReportScreen extends StatefulWidget {
  const IssueReportScreen({super.key});

  @override
  State<IssueReportScreen> createState() => _IssueReportScreenState();
}

class _IssueReportScreenState extends State<IssueReportScreen> {
  static const String _otherCategoryTitle = 'Other';
  String? selectedIssue;
  final TextEditingController otherIssueController = TextEditingController();
  List<String> selectedMediaPaths = [];
  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, VideoPlayerController> _videoControllers = {};

  // API fetched categories
  List<IssueCategory> _issueCategories = [];
  bool _isLoadingCategories = true;
  String? _categoryError;

  // Selected location
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedLocationAddress;

  // Number plate
  String? _numberPlate;

  // Coupon code
  final TextEditingController _couponController = TextEditingController();
  bool _couponApplied = false;
  bool _hasShownCouponAnimation =
      false; // Track if we've already shown the animation

  @override
  void initState() {
    super.initState();
    print('🟢 [IssueReportScreen] initState - Screen initialized');
    _fetchIssueCategories();
    _loadNumberPlate();
  }

  Future<void> _loadNumberPlate() async {
    final plate = await VehicleStorage.getVehicleNumber();
    setState(() {
      _numberPlate = plate;
    });
  }

  Future<void> _fetchIssueCategories() async {
    print(
      '🟢 [IssueReportScreen] _fetchIssueCategories - Starting to fetch categories',
    );
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      final repository = IssueReportRepository();
      final categories = await repository.fetchIssueCategories();

      print(
        '✅ [IssueReportScreen] Categories fetched successfully: ${categories.length}',
      );

      if (mounted) {
        setState(() {
          _issueCategories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      print('❌ [IssueReportScreen] Error fetching categories: $e');
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
          _categoryError = e.toString();
        });
      }
    }
  }

  // Map category name to icon
  IconData _getIconForCategory(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('battery') && name.contains('charging')) {
      return Icons.battery_charging_full;
    } else if (name.contains('mechanical')) {
      return Icons.build;
    } else if (name.contains('battery') && name.contains('swap')) {
      return Icons.battery_alert;
    } else if (name.contains('tyre') || name.contains('tire')) {
      return Icons.tire_repair;
    } else if (name.contains('tow') || name.contains('pickup')) {
      return Icons.local_shipping;
    } else if (name.contains('other')) {
      return Icons.more_horiz;
    }
    return Icons.help_outline; // Default icon
  }

  // Convert API categories to UI format
  List<Map<String, dynamic>> get _displayCategories {
    if (_isLoadingCategories || _issueCategories.isEmpty) {
      return [];
    }

    return _issueCategories.map((category) {
      return {
        'title': category.name,
        'icon': _getIconForCategory(category.name),
        'id': category.id,
      };
    }).toList();
  }

  @override
  void dispose() {
    print('🔴 [IssueReportScreen] dispose - Screen disposed');
    // Dispose all video controllers
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    otherIssueController.dispose();
    _couponController.dispose();
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
            'Issue Reporting',
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
            print(
              '🟡 [IssueReportScreen] BlocListener - State changed: ${state.status}',
            );

            // Handle coupon validation - only show animation when coupon is validated, not during ticket submission
            // Only check coupon validation state if we're not in a ticket submission state
            if (state.status != IssueReportStatus.loading &&
                state.status != IssueReportStatus.uploading &&
                state.status != IssueReportStatus.success) {
              if (state.isValidatingCoupon) {
                // Show loading indicator if needed
                _hasShownCouponAnimation =
                    false; // Reset flag when starting new validation
              } else if (state.couponValidated &&
                  state.couponValidationData != null &&
                  !_hasShownCouponAnimation) {
                // Coupon validated successfully - show animation only once
                print('✅ [IssueReportScreen] Coupon validated successfully');
                setState(() {
                  _couponApplied = true;
                  _hasShownCouponAnimation =
                      true; // Mark that we've shown the animation
                });
                _showCouponSuccessAnimation();
              } else if (state.couponValidationError != null &&
                  !state.isValidatingCoupon &&
                  !_hasShownCouponAnimation) {
                // Coupon validation failed - only show error if we haven't shown animation yet
                print(
                  '❌ [IssueReportScreen] Coupon validation failed: ${state.couponValidationError}',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.couponValidationError!),
                    backgroundColor: Colors.red,
                  ),
                );
                _hasShownCouponAnimation =
                    true; // Mark to prevent showing again
              }
            }

            if (state.isSuccess) {
              print(
                '✅ [IssueReportScreen] Success! Navigating to success screen',
              );
              print('✅ [IssueReportScreen] Message: ${state.message}');
              print(
                '✅ [IssueReportScreen] Payment required: ${state.paymentRequired}',
              );
              print('✅ [IssueReportScreen] Payment URL: ${state.paymentUrl}');
              print('✅ [IssueReportScreen] Ticket ID: ${state.ticket?.id}');
              if (state.ticket != null && state.ticket!.ticketId.isNotEmpty) {
                print(
                  '✅ [IssueReportScreen] Ticket ID (ticket_id): ${state.ticket!.ticketId}',
                );
              }

              // Check if payment is required
              if (state.paymentRequired == true &&
                  state.paymentUrl != null &&
                  state.paymentUrl!.isNotEmpty) {
                print(
                  '💳 [IssueReportScreen] Payment required, navigating to payment URL',
                );
                _launchPaymentUrl(state.paymentUrl!);
              } else {
                // Clear form fields after successful submission
                _clearFormFields();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => SuccessScreen(
                      isSuccess: true,
                      message:
                          state.message ??
                          'Service ticket created successfully',
                      ticket: state.ticket,
                    ),
                  ),
                );
              }
            } else if (state.isFailure) {
              print(
                '❌ [IssueReportScreen] Failure! Error message: ${state.message}',
              );
              print('❌ [IssueReportScreen] Status code: ${state.statusCode}');

              // Check if user is unauthenticated (401)
              if (state.statusCode == 401) {
                print(
                  '🔐 [IssueReportScreen] User unauthenticated - Clearing token and navigating to login',
                );
                // Clear token and navigate to login screen
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
              } else {
                // For other errors, navigate to error screen
                print('❌ [IssueReportScreen] Navigating to error screen');
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Issue Categories
                    if (_isLoadingCategories)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_categoryError != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Failed to load categories',
                              style: TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _fetchIssueCategories,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else if (_displayCategories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text('No categories available')),
                      )
                    else
                      ..._displayCategories.map(
                        (category) => _buildIssueCategory(
                          title: category['title'] as String,
                          icon: category['icon'] as IconData,
                        ),
                      ),

                    if (selectedIssue == _otherCategoryTitle) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Describe your issue',
                        style: TextStyle(
                          color: AppColors.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: otherIssueController,
                          decoration: InputDecoration(
                            hintText: 'Type your issue',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: 3,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Number Plate Section
                    const SizedBox(height: 24),
                    const Text(
                      'Vehicle Number Plate',
                      style: TextStyle(
                        color: AppColors.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _showNumberPlateBottomSheet,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                _numberPlate != null && _numberPlate!.isNotEmpty
                                ? Colors.black
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.confirmation_number,
                                color: Colors.black,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _numberPlate ?? 'Tap to enter number plate',
                                style: TextStyle(
                                  color:
                                      _numberPlate != null &&
                                          _numberPlate!.isNotEmpty
                                      ? AppColors.textColor
                                      : Colors.grey.shade600,
                                  fontSize: 14,
                                  fontWeight:
                                      _numberPlate != null &&
                                          _numberPlate!.isNotEmpty
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey.shade400,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Location Section
                    const SizedBox(height: 24),
                    const Text(
                      'Select Location',
                      style: TextStyle(
                        color: AppColors.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _selectLocation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedLocationAddress != null
                                ? Colors.black
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.black,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedLocationAddress ??
                                        'Tap to select location',
                                    style: TextStyle(
                                      color: _selectedLocationAddress != null
                                          ? AppColors.textColor
                                          : Colors.grey.shade600,
                                      fontSize: 14,
                                      fontWeight:
                                          _selectedLocationAddress != null
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_selectedLatitude != null &&
                                      _selectedLongitude != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_selectedLatitude!.toStringAsFixed(6)}, ${_selectedLongitude!.toStringAsFixed(6)}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey.shade400,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Upload Section
                    const SizedBox(height: 24),
                    const Text(
                      'Upload your issue',
                      style: TextStyle(
                        color: AppColors.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Show preview if media is selected, otherwise show upload button
                    if (selectedMediaPaths.isEmpty)
                      _buildUploadButton()
                    else
                      _buildMediaGrid(),

                    const SizedBox(height: 32),

                    // Upload Progress Indicator
                    if (state.isUploading && state.uploadProgress != null) ...[
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        _formatDuration(state.elapsedSeconds!),
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

                    // Coupon Code Section
                    const Text(
                      'Coupon Code',
                      style: TextStyle(
                        color: AppColors.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    (_couponController.text.isNotEmpty &&
                                        !_couponApplied)
                                    ? Colors.black
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: TextField(
                              controller: _couponController,
                              decoration: InputDecoration(
                                hintText: 'Enter coupon code',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              style: const TextStyle(
                                color: AppColors.textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              enabled: !_couponApplied,
                              onChanged: (value) {
                                setState(() {
                                  // Trigger rebuild to update border color
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Opacity(
                          opacity: _couponApplied ? 0.5 : 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _couponApplied ? null : _applyCoupon,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  child: Text(
                                    _couponApplied ? 'Applied' : 'Apply',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30),

                    // Submit Button
                    OneBtn(
                      text: state.isLoading
                          ? (state.isUploading
                                ? 'Uploading...'
                                : 'Submitting...')
                          : 'Submit Request',
                      onPressed: state.isLoading ? null : _handleSubmit,
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIssueCategory({required String title, required IconData icon}) {
    final isSelected = selectedIssue == title;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedIssue = title;
            // Clear other text when a predefined category (non-Other) is selected
            if (title != _otherCategoryTitle &&
                otherIssueController.text.isNotEmpty) {
              otherIssueController.clear();
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUploadTap() async {
    // Show native iOS-style action sheet
    if (Platform.isIOS) {
      showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
          title: const Text('Choose Media'),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _pickMultipleImages();
              },
              child: const Text('Choose Photos from Library'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _pickMultipleVideos();
              },
              child: const Text('Choose Videos from Library'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      // For Android, use Material bottom sheet
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
  }

  Future<void> _pickMultipleImages() async {
    try {
      // image_picker handles permissions automatically on iOS
      final List<XFile>? images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );

      if (images != null && images.isNotEmpty && mounted) {
        setState(() {
          selectedMediaPaths.addAll(images.map((img) => img.path));
        });
      }
    } catch (e) {
      print('❌ [IssueReportScreen] Error picking images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickMultipleVideos() async {
    try {
      // image_picker handles permissions automatically on iOS
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null && mounted) {
        setState(() {
          selectedMediaPaths.add(video.path);
        });
        _initializeVideoPlayer(video.path);
      }
    } catch (e) {
      print('❌ [IssueReportScreen] Error picking video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking video: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _initializeVideoPlayer(String videoPath) async {
    if (_videoControllers.containsKey(videoPath)) {
      return; // Already initialized
    }

    try {
      final controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize();
      if (mounted) {
        setState(() {
          _videoControllers[videoPath] = controller;
        });
      }
    } catch (e) {
      print('❌ [IssueReportScreen] Error initializing video player: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading video preview')),
        );
      }
    }
  }

  Future<void> _selectLocation() async {
    print('📍 [IssueReportScreen] Opening location selection screen');
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (context) => const LocationSelectionScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLatitude = result['latitude'] as double;
        _selectedLongitude = result['longitude'] as double;
        _selectedLocationAddress = result['address'] as String;
      });
      print(
        '✅ [IssueReportScreen] Location selected: $_selectedLocationAddress',
      );
      print(
        '✅ [IssueReportScreen] Coordinates: $_selectedLatitude, $_selectedLongitude',
      );
    }
  }

  void _clearFormFields() {
    // Dispose all video controllers
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    setState(() {
      selectedIssue = null;
      selectedMediaPaths.clear();
      _videoControllers.clear();
      otherIssueController.clear();
      _selectedLatitude = null;
      _selectedLongitude = null;
      _selectedLocationAddress = null;
      // Don't clear number plate - keep it for next submission
      // Reset coupon animation flag for next submission
      _hasShownCouponAnimation = false;
    });
    print('🧹 [IssueReportScreen] Form fields cleared');
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

  void _showNumberPlateBottomSheet() {
    final TextEditingController numberPlateController = TextEditingController(
      text: _numberPlate ?? '',
    );

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
                'Enter Vehicle Number Plate',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),

              const SizedBox(height: 20),

              // Number Plate Input Field
              TextField(
                controller: numberPlateController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Vehicle Number Plate',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                autofocus: true,
              ),

              const SizedBox(height: 12),

              // Helper text
              Text(
                'Enter your vehicle registration number',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 24),

              // Submit Button
              OneBtn(
                text: 'Save',
                onPressed: () {
                  final plate = numberPlateController.text.trim();
                  if (plate.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a number plate'),
                      ),
                    );
                    return;
                  }

                  // Save to storage
                  VehicleStorage.getVehicleName().then((vehicleName) async {
                    await VehicleStorage.saveVehicleInfo(
                      name: vehicleName ?? 'My Vehicle',
                      number: plate,
                      vehicleTypeId: await VehicleStorage.getVehicleTypeId(),
                      brandId: await VehicleStorage.getBrandId(),
                      modelId: await VehicleStorage.getModelId(),
                    );
                  });

                  setState(() {
                    _numberPlate = plate;
                  });

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Number plate saved'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _removeMedia(int index) {
    final path = selectedMediaPaths[index];
    // Dispose video controller if it exists
    if (_videoControllers.containsKey(path)) {
      _videoControllers[path]!.dispose();
      _videoControllers.remove(path);
    }
    setState(() {
      selectedMediaPaths.removeAt(index);
    });
  }

  Widget _buildUploadButton() {
    return GestureDetector(
      key: const ValueKey('upload_button'),
      onTap: _handleUploadTap,
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
              'Add photos or short video',
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload photos or videos to help us understand and resolve your issue better.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid of media items
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: selectedMediaPaths.length + 1, // +1 for add button
          itemBuilder: (context, index) {
            if (index == selectedMediaPaths.length) {
              // Add button
              return _buildAddMediaButton();
            }
            return _buildMediaItem(selectedMediaPaths[index], index);
          },
        ),
      ],
    );
  }

  Widget _buildAddMediaButton() {
    return GestureDetector(
      onTap: _handleUploadTap,
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 32,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 8),
            Text(
              'Add More',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaItem(String mediaPath, int index) {
    final isVideo = _isVideoFile(mediaPath);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Media Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isVideo
                ? _buildVideoPreview(mediaPath)
                : _buildImagePreview(mediaPath),
          ),
          // Close button
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => _removeMedia(index),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
          // Video indicator
          if (isVideo)
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isVideoFile(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.mp4') ||
        lowerPath.endsWith('.mov') ||
        lowerPath.endsWith('.avi') ||
        lowerPath.endsWith('.mkv');
  }

  Widget _buildImagePreview(String imagePath) {
    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.broken_image, size: 32, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildVideoPreview(String videoPath) {
    final controller = _videoControllers[videoPath];

    if (controller == null || !controller.value.isInitialized) {
      // Show placeholder while loading
      return GestureDetector(
        onTap: () => _initializeVideoPlayer(videoPath),
        child: Container(
          color: Colors.black,
          child: const Center(
            child: Icon(
              Icons.play_circle_filled,
              size: 48,
              color: Colors.white70,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showVideoPlayer(videoPath),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video thumbnail (first frame)
          VideoPlayer(controller),
          // Play button overlay
          if (!controller.value.isPlaying)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Icon(
                  Icons.play_circle_filled,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showVideoPlayer(String videoPath) {
    final controller = _videoControllers[videoPath];
    if (controller == null) {
      _initializeVideoPlayer(videoPath).then((_) {
        if (mounted && _videoControllers.containsKey(videoPath)) {
          _showVideoPlayerDialog(videoPath);
        }
      });
      return;
    }

    _showVideoPlayerDialog(videoPath);
  }

  void _showVideoPlayerDialog(String videoPath) {
    final controller = _videoControllers[videoPath];
    if (controller == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: _VideoPlayerDialog(controller: controller, videoPath: videoPath),
      ),
    );
  }

  void _applyCoupon() {
    final couponCode = _couponController.text.trim();
    if (couponCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a coupon code')),
      );
      return;
    }

    // Validate coupon code via API
    context.read<IssueReportBloc>().add(
      ValidateRedeemCode(redeemCode: couponCode),
    );
  }

  void _showCouponSuccessAnimation() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.width * 0.8,
                  child: Lottie.asset(
                    'assets/issue/successfully-done.json',
                    fit: BoxFit.contain,
                    repeat: false,
                    onLoaded: (composition) {
                      // Auto-close dialog after animation completes
                      Future.delayed(composition.duration, () {
                        if (mounted && Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    print('🚀 [IssueReportScreen] ========== _handleSubmit START ==========');
    print('🚀 [IssueReportScreen] Submit button clicked');

    // Validate category selection
    if (selectedIssue == null) {
      print('⚠️ [IssueReportScreen] Validation failed - No category selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an issue category')),
      );
      return;
    }

    // Find selected category ID
    final selectedCategory = _issueCategories.firstWhere(
      (cat) => cat.name == selectedIssue,
      orElse: () => _issueCategories.first,
    );
    final issueCategoryId = selectedCategory.id;
    print(
      '📋 [IssueReportScreen] Selected category: ${selectedCategory.name} (ID: $issueCategoryId)',
    );

    // Get vehicle IDs from storage
    final vehicleTypeId = await VehicleStorage.getVehicleTypeId();
    final brandId = await VehicleStorage.getBrandId();
    final modelId = await VehicleStorage.getModelId();

    print('📋 [IssueReportScreen] Vehicle Type ID: $vehicleTypeId');
    print('📋 [IssueReportScreen] Brand ID: $brandId');
    print('📋 [IssueReportScreen] Model ID: $modelId');

    if (vehicleTypeId == null || brandId == null || modelId == null) {
      print(
        '⚠️ [IssueReportScreen] Validation failed - Vehicle information incomplete',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your vehicle information first'),
        ),
      );
      return;
    }

    // Validate number plate
    if (_numberPlate == null || _numberPlate!.trim().isEmpty) {
      print('⚠️ [IssueReportScreen] Validation failed - Number plate required');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your vehicle number plate')),
      );
      _showNumberPlateBottomSheet();
      return;
    }

    // Get selected location or use current location
    double latitude;
    double longitude;
    String location;

    if (_selectedLatitude != null &&
        _selectedLongitude != null &&
        _selectedLocationAddress != null) {
      // Use selected location
      latitude = _selectedLatitude!;
      longitude = _selectedLongitude!;
      location = _selectedLocationAddress!;
      print('📍 [IssueReportScreen] Using selected location: $location');
      print('📍 [IssueReportScreen] Coordinates: $latitude, $longitude');
    } else {
      // Fallback to current location
      print(
        '📍 [IssueReportScreen] No location selected, getting current location...',
      );
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        latitude = position.latitude;
        longitude = position.longitude;

        // Try to get address from reverse geocoding
        try {
          final placemarks = await placemarkFromCoordinates(
            latitude,
            longitude,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            location = [
              place.street,
              place.locality,
              place.administrativeArea,
              place.country,
            ].where((s) => s != null && s.isNotEmpty).join(', ');
          } else {
            location = 'Lat: $latitude, Lng: $longitude';
          }
        } catch (e) {
          print('⚠️ [IssueReportScreen] Could not get address: $e');
          location = 'Lat: $latitude, Lng: $longitude';
        }

        print('📍 [IssueReportScreen] Current location: $location');
        print('📍 [IssueReportScreen] Coordinates: $latitude, $longitude');
      } catch (e) {
        print('⚠️ [IssueReportScreen] Could not get location: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select a location or enable location services.',
            ),
          ),
        );
        return;
      }
    }

    print(
      '✅ [IssueReportScreen] Validation passed - Dispatching IssueReportSubmitted event',
    );

    // Submit issue report with all selected media files
    final mediaPaths = selectedMediaPaths.isNotEmpty
        ? selectedMediaPaths
        : null;

    // Get description if "Other" category is selected
    String? description;
    if (selectedIssue == _otherCategoryTitle &&
        otherIssueController.text.trim().isNotEmpty) {
      description = otherIssueController.text.trim();
    }

    // Get redeem code from coupon field if applied
    String? redeemCode;
    if (_couponApplied && _couponController.text.trim().isNotEmpty) {
      redeemCode = _couponController.text.trim();
    }

    context.read<IssueReportBloc>().add(
      IssueReportSubmitted(
        issueCategoryId: issueCategoryId,
        vehicleTypeId: vehicleTypeId,
        brandId: brandId,
        modelId: modelId,
        location: location,
        latitude: latitude,
        longitude: longitude,
        mediaPaths: mediaPaths,
        numberPlate: _numberPlate?.trim(),
        description: description,
        redeemCode: redeemCode,
      ),
    );
    print('✅ [IssueReportScreen] Event dispatched successfully');
    print('✅ [IssueReportScreen] ========== _handleSubmit SUCCESS ==========');
  }

  Future<void> _launchPaymentUrl(String url) async {
    print('💳 [IssueReportScreen] Navigating to custom PaymentWebViewScreen');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentWebViewScreen(paymentUrl: url),
      ),
    );
  }
}

// Video Player Dialog Widget
class _VideoPlayerDialog extends StatefulWidget {
  final VideoPlayerController controller;
  final String videoPath;

  const _VideoPlayerDialog({required this.controller, required this.videoPath});

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  bool _isPlaying = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_videoListener);
    _isPlaying = widget.controller.value.isPlaying;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_videoListener);
    super.dispose();
  }

  void _videoListener() {
    if (mounted) {
      setState(() {
        _isPlaying = widget.controller.value.isPlaying;
      });
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (widget.controller.value.isPlaying) {
        widget.controller.pause();
        _isPlaying = false;
      } else {
        widget.controller.play();
        _isPlaying = true;
      }
      _showControls = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player
          Center(
            child: AspectRatio(
              aspectRatio: widget.controller.value.aspectRatio,
              child: VideoPlayer(widget.controller),
            ),
          ),
          // Controls overlay
          if (_showControls)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Stack(
                children: [
                  // Close button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  // Play/Pause button
                  Center(
                    child: GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
