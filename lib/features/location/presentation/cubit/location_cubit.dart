import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/error/api_exception.dart';
import '../../data/repositories/location_repository.dart';
import '../../domain/entities/place_suggestion.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  LocationCubit({LocationRepository? repository})
      : _repository = repository ?? LocationRepository(),
        super(const LocationState());

  final LocationRepository _repository;

  Future<void> initialize() async {
    emit(state.copyWith(
      status: LocationStatus.loading,
      message: null,
      saveSuccess: false,
    ));

    final permissionGranted = await _ensurePermission();
    if (!permissionGranted) {
      emit(state.copyWith(
        status: LocationStatus.permissionDenied,
        message:
            'Location permissions are required to auto-detect your position.',
      ));
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(position.latitude, position.longitude);
      final address = await _repository.reverseGeocode(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );

      emit(state.copyWith(
        status: LocationStatus.ready,
        currentLocation: latLng,
        selectedLocation: latLng,
        selectedAddress: address ?? state.selectedAddress,
        saveSuccess: false,
        message: null,
        incrementCameraMove: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: LocationStatus.error,
        message: 'Unable to fetch current location. Please try again.',
      ));
    }
  }

  Future<void> refreshCurrentLocation() async {
    final permissionGranted = await _ensurePermission();
    if (!permissionGranted) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(position.latitude, position.longitude);
      final address = await _repository.reverseGeocode(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );

      emit(state.copyWith(
        status: LocationStatus.ready,
        currentLocation: latLng,
        selectedLocation: latLng,
        selectedAddress: address ?? state.selectedAddress,
        saveSuccess: false,
        message: null,
        incrementCameraMove: true,
      ));
    } catch (_) {
      emit(state.copyWith(
        message: 'Unable to refresh location right now.',
        status: LocationStatus.error,
      ));
    }
  }

  Future<void> selectManualLocation(LatLng latLng) async {
    final address = await _repository.reverseGeocode(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );

    emit(state.copyWith(
      status: LocationStatus.ready,
      selectedLocation: latLng,
      selectedAddress: address ?? state.selectedAddress,
      saveSuccess: false,
      message: null,
      suggestions: const [],
      incrementCameraMove: true,
    ));
  }

  Future<void> searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      emit(state.copyWith(suggestions: const []));
      return;
    }

    try {
      final results = await _repository.searchPlaces(query);
      emit(state.copyWith(suggestions: results));
    } catch (_) {
      emit(state.copyWith(
        suggestions: const [],
        message: 'Unable to search places right now.',
        status: LocationStatus.error,
      ));
    }
  }

  Future<void> selectSuggestion(PlaceSuggestion suggestion) async {
    emit(state.copyWith(
      status: LocationStatus.loading,
      message: null,
    ));

    try {
      final point = await _repository.getPlaceLocation(suggestion.placeId);
      if (point == null) {
        emit(state.copyWith(
          status: LocationStatus.error,
          message: 'Unable to get selected place details.',
        ));
        return;
      }

      emit(state.copyWith(
        status: LocationStatus.ready,
        selectedLocation: LatLng(point.latitude, point.longitude),
        selectedAddress: suggestion.description,
        suggestions: const [],
        saveSuccess: false,
        incrementCameraMove: true,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: LocationStatus.error,
        message: 'Unable to get selected place details.',
      ));
    }
  }

  Future<void> saveSelectedLocation() async {
    final target = state.selectedLocation ?? state.currentLocation;
    if (target == null) {
      emit(state.copyWith(
        message: 'Select a location before saving.',
        status: LocationStatus.error,
      ));
      return;
    }

    emit(state.copyWith(
      isSaving: true,
      saveSuccess: false,
      message: null,
    ));

    try {
      final response = await _repository.sendLocation(
        latitude: target.latitude,
        longitude: target.longitude,
        address: state.selectedAddress,
      );

      emit(state.copyWith(
        status: LocationStatus.ready,
        isSaving: false,
        saveSuccess: true,
        lastResponse: response,
        message: response.message ?? 'Location saved successfully.',
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(
        isSaving: false,
        saveSuccess: false,
        status: LocationStatus.error,
        message: error.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        isSaving: false,
        saveSuccess: false,
        status: LocationStatus.error,
        message: 'Unable to save location. Please try again.',
      ));
    }
  }

  void clearSuggestions() {
    if (state.suggestions.isEmpty) return;
    emit(state.copyWith(suggestions: const []));
  }

  Future<bool> _ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      emit(state.copyWith(
        status: LocationStatus.error,
        message: 'Please enable location services.',
      ));
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      emit(state.copyWith(
        status: LocationStatus.permissionDenied,
        message:
            'Location permissions are permanently denied. Please enable them from settings.',
      ));
      return false;
    }

    return true;
  }
}


