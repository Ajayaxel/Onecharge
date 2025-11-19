import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:onecharge/features/location/presentation/cubit/location_cubit.dart';
import 'package:onecharge/features/location/presentation/cubit/location_state.dart';

class HomeGoogleMap extends StatefulWidget {
  const HomeGoogleMap({super.key});

  @override
  State<HomeGoogleMap> createState() => _HomeGoogleMapState();
}

class _HomeGoogleMapState extends State<HomeGoogleMap> {
  static const LatLng _defaultLocation = LatLng(24.276987, 55.296249);

  GoogleMapController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LocationCubit, LocationState>(
      listenWhen: (previous, current) =>
          previous.cameraMoveId != current.cameraMoveId,
      listener: (context, state) async {
        final target = state.selectedLocation ?? state.currentLocation;
        if (target == null || _controller == null) return;

        await _controller!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: 15),
          ),
        );
      },
      builder: (context, state) {
        final target = state.selectedLocation ?? state.currentLocation;
        final markers = <Marker>{};

        if (target != null) {
          markers.add(
            Marker(
              markerId: const MarkerId('selected-location'),
              position: target,
              infoWindow: InfoWindow(
                title: 'Dispatch location',
                snippet: state.selectedAddress ??
                    '${target.latitude.toStringAsFixed(4)}, ${target.longitude.toStringAsFixed(4)}',
              ),
              draggable: true,
              onDragEnd: (position) {
                context.read<LocationCubit>().selectManualLocation(position);
              },
            ),
          );
        }

        return Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: target ?? _defaultLocation,
                zoom: target != null ? 15 : 11,
              ),
              markers: markers,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              myLocationEnabled: state.currentLocation != null,
              compassEnabled: true,
              onMapCreated: (controller) {
                _controller = controller;
              },
              onTap: (position) {
                context.read<LocationCubit>().selectManualLocation(position);
              },
            ),
            if (state.status == LocationStatus.loading)
              const Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

