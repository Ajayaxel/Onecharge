import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onecharge/const/onebtn.dart';
import 'package:onecharge/core/storage/vehicle_storage.dart';
import 'package:onecharge/features/issue_report/data/repositories/issue_report_repository.dart';
import 'package:onecharge/features/issue_report/presentation/bloc/issue_report_bloc.dart';
import 'package:onecharge/features/location/domain/entities/place_suggestion.dart';
import 'package:onecharge/features/location/presentation/cubit/location_cubit.dart';
import 'package:onecharge/features/location/presentation/cubit/location_state.dart';
import 'package:onecharge/resources/app_resources.dart';
import 'package:onecharge/screen/home/widgets/home_google_map.dart';
import 'package:onecharge/screen/issue_report/issue_report_screen.dart';
import 'package:onecharge/screen/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _vehicleName;
  String? _vehicleNumber;
  String? _vehicleImage;
  late final LocationCubit _locationCubit;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _locationCubit = LocationCubit()..initialize();
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        _locationCubit.clearSuggestions();
      }
    });
    _loadVehicleInfo();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _locationCubit.close();
    super.dispose();
  }

  Future<void> _loadVehicleInfo() async {
    final name = await VehicleStorage.getVehicleName();
    final number = await VehicleStorage.getVehicleNumber();
    final image = await VehicleStorage.getVehicleImage();

    if (!mounted) return;

    setState(() {
      _vehicleName = name;
      _vehicleNumber = number;
      _vehicleImage = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicleName = _vehicleName ?? 'Select vehicle';
    final vehicleNumber = _vehicleNumber ?? 'Add vehicle number';

    return BlocProvider<LocationCubit>.value(
      value: _locationCubit,
      child: BlocListener<LocationCubit, LocationState>(
        listenWhen: (previous, current) =>
            previous.message != current.message && current.message != null,
        listener: (context, state) {
          final message = state.message;
          if (message == null) return;
          final color = state.saveSuccess ? Colors.green : Colors.red;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: color,
            ),
          );
        },
        child: Scaffold(
          body: Stack(
            children: [
              // Map Background
              const Positioned.fill(child: HomeGoogleMap()),

              // Top Section
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(vehicleName, vehicleNumber),
                    const SizedBox(height: 8),
                    _buildSearchSection(),
                    const SizedBox(height: 12),
                    _buildChipsSection(),
                  ],
                ),
              ),

              // Floating Buttons
              Positioned(
                right: 16,
                bottom: 180,
                child: SafeArea(
                  child: Builder(
                    builder: (context) => FloatingActionButton(
                      heroTag: 'my_location_fab',
                      backgroundColor: Colors.white,
                      onPressed: () =>
                          context.read<LocationCubit>().refreshCurrentLocation(),
                      child: const Icon(Icons.my_location, color: Colors.black87),
                    ),
                  ),
                ),
              ),

              // Bottom Section
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: BlocBuilder<LocationCubit, LocationState>(
                      builder: (context, state) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLocationSummary(context, state),
                            const SizedBox(height: 12),
                            OneBtn(
                              text: 'Send location to dispatch',
                              isLoading: state.isSaving,
                              onPressed: () => context
                                  .read<LocationCubit>()
                                  .saveSelectedLocation(),
                            ),
                            const SizedBox(height: 12),
                            _buildIssueReportButton(),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(String vehicleName, String vehicleNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color.fromRGBO(255, 255, 255, 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildVehicleLogo(),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      vehicleName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    Text(
                      vehicleNumber,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: Image.network(
                  'https://icons.veryicon.com/png/o/miscellaneous/user-avatar/user-avatar-male-5.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.black,
                      child: const Icon(Icons.person),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(0, 0, 0, 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (value) =>
                        _locationCubit.searchPlaces(value.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search or drop a pin...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade600,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.tune, color: Colors.grey.shade800),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          BlocBuilder<LocationCubit, LocationState>(
            builder: (context, state) {
              if (state.suggestions.isEmpty) {
                return const SizedBox.shrink();
              }
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final PlaceSuggestion suggestion = state.suggestions[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(
                        suggestion.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        _searchController.text = suggestion.description;
                        _searchFocusNode.unfocus();
                        context
                            .read<LocationCubit>()
                            .selectSuggestion(suggestion);
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: Color(0xFFE9E9E9),
                  ),
                  itemCount: state.suggestions.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChipsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildChip('Auto-detect via GPS', Icons.gps_fixed),
            _buildChip('Manual pin drop', Icons.push_pin_outlined),
            _buildChip('Search & dispatch', Icons.route_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSummary(BuildContext context, LocationState state) {
    final target = state.selectedLocation ?? state.currentLocation;
    final latitude = target?.latitude;
    final longitude = target?.longitude;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                state.status == LocationStatus.ready
                    ? Icons.check_circle
                    : Icons.gps_not_fixed,
                color: state.status == LocationStatus.ready
                    ? Colors.green
                    : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.selectedAddress ??
                      (target != null
                          ? 'Selected location ready for dispatch'
                          : 'Waiting for location...'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    context.read<LocationCubit>().refreshCurrentLocation(),
                child: const Text('Use GPS'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.push_pin_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tap map to place pin or drag the marker to refine manual location.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (latitude != null && longitude != null)
            Row(
              children: [
                _buildCoordinateTile('Latitude', latitude),
                const SizedBox(width: 12),
                _buildCoordinateTile('Longitude', longitude),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCoordinateTile(String label, double value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.toStringAsFixed(6),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueReportButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (context) => IssueReportBloc(
                    IssueReportRepository(),
                  ),
                  child: const IssueReportScreen(),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.report_problem_outlined,
                  color: AppColors.primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Report an Issue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.primaryColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleLogo() {
    final image = _vehicleImage;
    if (image != null && image.isNotEmpty) {
      if (image.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            image,
            width: 24,
            height: 24,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.electric_car, size: 24);
            },
          ),
        );
      } else {
        return Image.asset(
          image,
          width: 24,
          height: 24,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.electric_car, size: 24);
          },
        );
      }
    }

    return Image.asset(
      'assets/vehicle/tesla.png',
      width: 24,
      height: 24,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.electric_car, size: 24);
      },
    );
  }
}
