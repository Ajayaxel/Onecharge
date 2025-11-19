import 'package:geocoding/geocoding.dart';
import 'package:google_place/google_place.dart';

import '../../../../core/config/google_maps_config.dart';
import '../datasources/location_api_service.dart';
import '../models/location_response.dart';
import '../../domain/entities/location_point.dart';
import '../../domain/entities/place_suggestion.dart';

class LocationRepository {
  LocationRepository({
    LocationApiService? apiService,
    GooglePlace? googlePlace,
  })  : _apiService = apiService ?? LocationApiService(),
        _googlePlace = googlePlace ?? GooglePlace(GoogleMapsConfig.apiKey);

  final LocationApiService _apiService;
  final GooglePlace _googlePlace;

  Future<LocationResponse> sendLocation({
    required double latitude,
    required double longitude,
    String? address,
  }) {
    return _apiService.sendLocation(
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
  }

  Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return [];

    final response = await _googlePlace.autocomplete.get(
      trimmed,
      types: 'geocode',
      language: 'en',
    );

    final predictions = response?.predictions;
    if (predictions == null) return [];

    return predictions
        .where((prediction) =>
            prediction.description != null && prediction.placeId != null)
        .map(
          (prediction) => PlaceSuggestion(
            description: prediction.description!,
            placeId: prediction.placeId!,
          ),
        )
        .toList();
  }

  Future<LocationPoint?> getPlaceLocation(String placeId) async {
    final details = await _googlePlace.details.get(placeId, language: 'en');
    final location = details?.result?.geometry?.location;
    if (location == null) return null;

    return LocationPoint(latitude: location.lat ?? 0, longitude: location.lng ?? 0);
  }

  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return null;
      final place = placemarks.first;
      final parts = [
        if ((place.name ?? '').isNotEmpty) place.name,
        if ((place.street ?? '').isNotEmpty) place.street,
        if ((place.locality ?? '').isNotEmpty) place.locality,
        if ((place.administrativeArea ?? '').isNotEmpty) place.administrativeArea,
        if ((place.country ?? '').isNotEmpty) place.country,
      ].whereType<String>().toList();
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }
}


