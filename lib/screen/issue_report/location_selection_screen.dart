import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:onecharge/const/onebtn.dart';
import 'package:onecharge/features/location/domain/entities/place_suggestion.dart';
import 'package:onecharge/features/location/presentation/cubit/location_cubit.dart';
import 'package:onecharge/features/location/presentation/cubit/location_state.dart';
import 'package:onecharge/resources/app_resources.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  late final LocationCubit _locationCubit;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  GoogleMapController? _mapController;
  static const LatLng _defaultLocation = LatLng(11.6994, 76.0773);
  int _lastCameraMoveId = 0;

  @override
  void initState() {
    super.initState();
    _locationCubit = LocationCubit()..initialize();
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        _locationCubit.clearSuggestions();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _locationCubit.close();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // If current location is already available, animate to it
    final state = _locationCubit.state;
    final target = state.currentLocation ?? state.selectedLocation;
    if (target != null) {
      _animateToLocation(target);
    }
  }

  Future<void> _animateToLocation(LatLng location) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: location,
            zoom: 15,
          ),
        ),
      );
    }
  }

  void _onMapTap(LatLng position) {
    _locationCubit.selectManualLocation(position);
  }

  void _onMarkerDragEnd(LatLng position) {
    _locationCubit.selectManualLocation(position);
  }

  void _onLocationSelected() {
    final state = _locationCubit.state;
    final location = state.selectedLocation ?? state.currentLocation;
    
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Return selected location data
    Navigator.of(context).pop({
      'latitude': location.latitude,
      'longitude': location.longitude,
      'address': state.selectedAddress ?? 'Selected location',
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LocationCubit>.value(
      value: _locationCubit,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Select Location',
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // Map
            BlocListener<LocationCubit, LocationState>(
              listener: (context, state) {
                // Animate to current location when it's fetched
                if (state.cameraMoveId != _lastCameraMoveId && state.cameraMoveId > 0) {
                  _lastCameraMoveId = state.cameraMoveId;
                  final target = state.selectedLocation ?? state.currentLocation;
                  if (target != null && _mapController != null) {
                    _animateToLocation(target);
                  }
                }
              },
              child: BlocBuilder<LocationCubit, LocationState>(
                builder: (context, state) {
                  final target = state.selectedLocation ?? state.currentLocation ?? _defaultLocation;
                  final markers = <Marker>{};

                  markers.add(
                    Marker(
                      markerId: const MarkerId('selected-location'),
                      position: target,
                      infoWindow: InfoWindow(
                        title: 'Issue Location',
                        snippet: state.selectedAddress ??
                            '${target.latitude.toStringAsFixed(4)}, ${target.longitude.toStringAsFixed(4)}',
                      ),
                      draggable: true,
                      onDragEnd: _onMarkerDragEnd,
                    ),
                  );

                  return GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: target,
                      zoom: target == _defaultLocation ? 11 : 15,
                    ),
                    markers: markers,
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    myLocationEnabled: state.currentLocation != null,
                    compassEnabled: true,
                    onMapCreated: _onMapCreated,
                    onTap: _onMapTap,
                  );
                },
              ),
            ),

            // Search Section
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSearchSection(),
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
                                  context.read<LocationCubit>().selectSuggestion(suggestion);
                                },
                              );
                            },
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: Color(0xFFE9E9E9)),
                            itemCount: state.suggestions.length,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Location Info & Button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: BlocBuilder<LocationCubit, LocationState>(
                    builder: (context, state) {
                      final target = state.selectedLocation ?? state.currentLocation;
                      final latitude = target?.latitude;
                      final longitude = target?.longitude;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Location Summary Card
                          Container(
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
                                                ? 'Selected location ready'
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
                                        'Tap map to place pin or drag the marker to refine location.',
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                                if (latitude != null && longitude != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _buildCoordinateTile('Latitude', latitude),
                                      const SizedBox(width: 12),
                                      _buildCoordinateTile('Longitude', longitude),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Select Location Button
                          OneBtn(
                            text: 'Select This Location',
                            onPressed: state.status == LocationStatus.ready
                                ? _onLocationSelected
                                : null,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // My Location FAB
            // Positioned(
            //   right: 16,
            //   bottom: 280,
            //   child: SafeArea(
            //     child: FloatingActionButton(
            //       heroTag: 'my_location_fab_issue',
            //       backgroundColor: Colors.white,
            //       onPressed: () => context.read<LocationCubit>().refreshCurrentLocation(),
            //       child: const Icon(
            //         Icons.my_location,
            //         color: Colors.black87,
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
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
        onChanged: (value) => _locationCubit.searchPlaces(value.trim()),
        decoration: InputDecoration(
          hintText: 'Search location...',
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

