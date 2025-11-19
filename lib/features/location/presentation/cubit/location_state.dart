import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models/location_response.dart';
import '../../domain/entities/place_suggestion.dart';

enum LocationStatus {
  initial,
  loading,
  ready,
  permissionDenied,
  error,
}

class LocationState extends Equatable {
  final LocationStatus status;
  final bool isSaving;
  final bool saveSuccess;
  final LatLng? currentLocation;
  final LatLng? selectedLocation;
  final String? selectedAddress;
  final String? message;
  final List<PlaceSuggestion> suggestions;
  final LocationResponse? lastResponse;
  final int cameraMoveId;

  const LocationState({
    this.status = LocationStatus.initial,
    this.isSaving = false,
    this.saveSuccess = false,
    this.currentLocation,
    this.selectedLocation,
    this.selectedAddress,
    this.message,
    this.suggestions = const [],
    this.lastResponse,
    this.cameraMoveId = 0,
  });

  LocationState copyWith({
    LocationStatus? status,
    bool? isSaving,
    bool? saveSuccess,
    LatLng? currentLocation,
    LatLng? selectedLocation,
    String? selectedAddress,
    String? message,
    List<PlaceSuggestion>? suggestions,
    LocationResponse? lastResponse,
    bool resetCameraMove = false,
    bool incrementCameraMove = false,
  }) {
    return LocationState(
      status: status ?? this.status,
      isSaving: isSaving ?? this.isSaving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      currentLocation: currentLocation ?? this.currentLocation,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      message: message,
      suggestions: suggestions ?? this.suggestions,
      lastResponse: lastResponse ?? this.lastResponse,
      cameraMoveId: incrementCameraMove
          ? cameraMoveId + 1
          : (resetCameraMove ? 0 : cameraMoveId),
    );
  }

  @override
  List<Object?> get props => [
        status,
        isSaving,
        saveSuccess,
        currentLocation,
        selectedLocation,
        selectedAddress,
        message,
        suggestions,
        lastResponse,
        cameraMoveId,
      ];
}


