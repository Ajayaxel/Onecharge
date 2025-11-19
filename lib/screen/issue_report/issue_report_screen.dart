import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:onecharge/const/onebtn.dart';
import 'package:onecharge/core/storage/token_storage.dart';
import 'package:onecharge/features/issue_report/presentation/bloc/issue_report_bloc.dart';
import 'package:onecharge/resources/app_resources.dart';
import 'package:onecharge/screen/issue_report/success_screen.dart';
import 'package:onecharge/screen/login/phone_login.dart';

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

  @override
  void initState() {
    super.initState();
    print('🟢 [IssueReportScreen] initState - Screen initialized');
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
    super.dispose();
  }

  final List<Map<String, dynamic>> issueCategories = [
    {
      'title': 'Low Battery / Charging Help',
      'icon': Icons.battery_charging_full,
    },
    {'title': 'Mechanical Issue', 'icon': Icons.build},
    {'title': 'Battery Swap Needed', 'icon': Icons.battery_alert},
    {'title': 'Flat Tyre', 'icon': Icons.tire_repair},
    {'title': 'Tow / Pickup Required', 'icon': Icons.local_shipping},
    {'title': _otherCategoryTitle, 'icon': Icons.more_horiz},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textColor),
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
            print('🟡 [IssueReportScreen] BlocListener - State changed: ${state.status}');
            if (state.isSuccess) {
              print('✅ [IssueReportScreen] Success! Navigating to success screen');
              print('✅ [IssueReportScreen] Message: ${state.message}');
              print('✅ [IssueReportScreen] Ticket ID: ${state.ticket?.id}');
              // Clear form fields after successful submission
              _clearFormFields();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => SuccessScreen(
                    isSuccess: true,
                    message: state.message ?? 'Service ticket created successfully',
                  ),
                ),
              );
            } else if (state.isFailure) {
              print('❌ [IssueReportScreen] Failure! Error message: ${state.message}');
              print('❌ [IssueReportScreen] Status code: ${state.statusCode}');
              
              // Check if user is unauthenticated (401)
              if (state.statusCode == 401) {
                print('🔐 [IssueReportScreen] User unauthenticated - Clearing token and navigating to login');
                // Clear token and navigate to login screen
                TokenStorage.clearToken().then((_) {
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const PhoneLogin()),
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
            ...issueCategories.map(
              (category) => _buildIssueCategory(
                title: category['title'],
                icon: category['icon'],
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

            // Upload Section
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

            // Submit Button
            OneBtn(
              text: state.isLoading ? 'Submitting...' : 'Submit Request',
              onPressed: state.isLoading ? null : _handleSubmit,
            ),

            const SizedBox(height: 16),
          ],
                ),
              );
            },
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
    print('📸 [IssueReportScreen] _handleUploadTap - Opening file picker options');
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
                print('📸 [IssueReportScreen] User selected: Choose Photos from Gallery');
                Navigator.pop(context);
                await _pickMultipleImages(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Choose Videos from Gallery'),
              onTap: () async {
                print('📸 [IssueReportScreen] User selected: Choose Videos from Gallery');
                Navigator.pop(context);
                await _pickMultipleVideos(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () async {
                print('📸 [IssueReportScreen] User selected: Take Photo');
                Navigator.pop(context);
                await _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record Video'),
              onTap: () async {
                print('📸 [IssueReportScreen] User selected: Record Video');
                Navigator.pop(context);
                await _pickVideo(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    print('🖼️ [IssueReportScreen] _pickImage - Source: $source');
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image != null) {
        print('✅ [IssueReportScreen] Image selected: ${image.path}');
        setState(() {
          selectedMediaPaths.add(image.path);
        });
        print('✅ [IssueReportScreen] Total media: ${selectedMediaPaths.length}');
      } else {
        print('⚠️ [IssueReportScreen] No image selected');
      }
    } catch (e) {
      print('❌ [IssueReportScreen] Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _pickMultipleImages(ImageSource source) async {
    print('🖼️ [IssueReportScreen] _pickMultipleImages - Source: $source');
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        print('✅ [IssueReportScreen] ${images.length} images selected');
        setState(() {
          selectedMediaPaths.addAll(images.map((img) => img.path));
        });
        print('✅ [IssueReportScreen] Total media: ${selectedMediaPaths.length}');
      } else {
        print('⚠️ [IssueReportScreen] No images selected');
      }
    } catch (e) {
      print('❌ [IssueReportScreen] Error picking images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    print('🎥 [IssueReportScreen] _pickVideo - Source: $source');
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null) {
        print('✅ [IssueReportScreen] Video selected: ${video.path}');
        setState(() {
          selectedMediaPaths.add(video.path);
        });
        _initializeVideoPlayer(video.path);
        print('✅ [IssueReportScreen] Total media: ${selectedMediaPaths.length}');
      } else {
        print('⚠️ [IssueReportScreen] No video selected');
      }
    } catch (e) {
      print('❌ [IssueReportScreen] Error picking video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking video: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _pickMultipleVideos(ImageSource source) async {
    print('🎥 [IssueReportScreen] _pickMultipleVideos - Source: $source');
    try {
      // Note: image_picker doesn't support picking multiple videos directly
      // We'll pick one at a time, but allow multiple selections
      final XFile? video = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null) {
        print('✅ [IssueReportScreen] Video selected: ${video.path}');
        setState(() {
          selectedMediaPaths.add(video.path);
        });
        _initializeVideoPlayer(video.path);
        print('✅ [IssueReportScreen] Total media: ${selectedMediaPaths.length}');
      } else {
        print('⚠️ [IssueReportScreen] No video selected');
      }
    } catch (e) {
      print('❌ [IssueReportScreen] Error picking video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking video: ${e.toString()}'),
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
      setState(() {
        _videoControllers[videoPath] = controller;
      });
    } catch (e) {
      print('❌ [IssueReportScreen] Error initializing video player: $e');
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
    });
    print('🧹 [IssueReportScreen] Form fields cleared');
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
              'Lorem Ipsum is simply dummy text of the printing and typesetting.',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
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
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
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
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          // Video indicator
          if (isVideo)
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
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
            child: Icon(
              Icons.broken_image,
              size: 32,
              color: Colors.grey,
            ),
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
        child: _VideoPlayerDialog(
          controller: controller,
          videoPath: videoPath,
        ),
      ),
    );
  }

  void _handleSubmit() {
    print('🚀 [IssueReportScreen] _handleSubmit - Submit button clicked');
    final category = selectedIssue;
    final otherText = otherIssueController.text.trim();

    print('📋 [IssueReportScreen] Category: $category');
    print('📋 [IssueReportScreen] Other text: $otherText');
    print('📋 [IssueReportScreen] Media paths: ${selectedMediaPaths.length}');

    if (category == null) {
      print('⚠️ [IssueReportScreen] Validation failed - No category selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an issue category'),
        ),
      );
      return;
    }

    String? finalOtherText;
    if (category == _otherCategoryTitle) {
      if (otherText.isEmpty) {
        print('⚠️ [IssueReportScreen] Validation failed - Other category requires description');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please describe your issue when selecting "Other"'),
          ),
        );
        return;
      }
      finalOtherText = otherText;
    }

    final finalCategory = category;

    print('✅ [IssueReportScreen] Validation passed - Dispatching IssueReportSubmitted event');
    print('✅ [IssueReportScreen] Final category: $finalCategory');
    print('✅ [IssueReportScreen] Final otherText: $finalOtherText');
    
    // Submit issue report (send first media for now, API supports single file)
    // TODO: Update API to support multiple files
    final mediaPath = selectedMediaPaths.isNotEmpty ? selectedMediaPaths.first : null;
    
    context.read<IssueReportBloc>().add(
          IssueReportSubmitted(
            category: finalCategory,
            otherText: finalOtherText,
            mediaPath: mediaPath,
          ),
        );
    print('✅ [IssueReportScreen] Event dispatched successfully');
  }
}

// Video Player Dialog Widget
class _VideoPlayerDialog extends StatefulWidget {
  final VideoPlayerController controller;
  final String videoPath;

  const _VideoPlayerDialog({
    required this.controller,
    required this.videoPath,
  });

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
