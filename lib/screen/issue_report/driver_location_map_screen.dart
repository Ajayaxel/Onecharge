import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:onecharge/features/issue_report/data/repositories/issue_report_repository.dart';
import 'package:onecharge/features/issue_report/data/models/driver_location_response.dart';
import 'package:onecharge/resources/app_resources.dart';
import 'package:onecharge/core/error/api_exception.dart';
import 'package:onecharge/core/websocket/reverb_websocket_service.dart';
import 'package:onecharge/core/storage/user_storage.dart';

class DriverLocationMapScreen extends StatefulWidget {
  const DriverLocationMapScreen({
    super.key,
    required this.ticketId,
    required this.ticketLatitude,
    required this.ticketLongitude,
    this.driverName,
  });

  final int ticketId;
  final double ticketLatitude;
  final double ticketLongitude;
  final String? driverName;

  @override
  State<DriverLocationMapScreen> createState() => _DriverLocationMapScreenState();
}

class _DriverLocationMapScreenState extends State<DriverLocationMapScreen> {
  final IssueReportRepository _repository = IssueReportRepository();
  final Completer<GoogleMapController> _mapController = Completer();
  final ReverbWebSocketService _websocketService = ReverbWebSocketService.instance;
  
  DriverLocation? _driverLocation;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _locationTimer;
  StreamSubscription<DriverLocationEvent>? _websocketSubscription;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _useWebSocket = false;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
    _fetchDriverLocation();
    // Fallback polling every 30 seconds if WebSocket fails
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !_useWebSocket) {
        _fetchDriverLocation(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _websocketSubscription?.cancel();
    // Don't disconnect WebSocket here as it might be used by other screens
    super.dispose();
  }

  Future<void> _initializeWebSocket() async {
    try {
      final user = await UserStorage.getUser();
      if (user == null || user.id == 0) {
        print('⚠️ [DriverLocationMap] No user found, skipping WebSocket initialization');
        return;
      }

      print('🔵 [DriverLocationMap] Initializing WebSocket for customer ID: ${user.id}');
      
      // Initialize WebSocket connection
      await _websocketService.initialize(customerId: user.id);
      
      // Subscribe to location updates
      _websocketSubscription = _websocketService.locationStream.listen(
        (event) {
          // Only update if this event is for the current ticket
          if (event.ticketId == widget.ticketId) {
            print('✅ [DriverLocationMap] WebSocket location update received');
            if (mounted) {
              setState(() {
                _driverLocation = DriverLocation(
                  id: event.driverId,
                  name: event.driverName,
                  latitude: event.latitude,
                  longitude: event.longitude,
                  lastLocationUpdatedAt: event.lastLocationUpdatedAt,
                );
                _useWebSocket = true;
              });
              _updateMapMarkers();
            }
          }
        },
        onError: (error) {
          print('❌ [DriverLocationMap] WebSocket error: $error');
          // Fallback to polling if WebSocket fails
          _useWebSocket = false;
        },
      );

      _websocketService.subscribeToTicket(widget.ticketId);
      print('✅ [DriverLocationMap] WebSocket initialized successfully');
    } catch (e) {
      print('❌ [DriverLocationMap] WebSocket initialization failed: $e');
      print('⚠️ [DriverLocationMap] Falling back to polling');
      _useWebSocket = false;
    }
  }

  Future<void> _fetchDriverLocation({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final response = await _repository.getDriverLocation(widget.ticketId);
      
      if (mounted) {
        setState(() {
          _driverLocation = response.data.driver;
          _isLoading = false;
          _errorMessage = null;
        });
        _updateMapMarkers();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (!silent) {
            _errorMessage = e.message;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (!silent) {
            _errorMessage = 'Failed to fetch driver location. Please try again.';
          }
        });
      }
    }
  }

  void _updateMapMarkers() {
    final markers = <Marker>{};
    final polylines = <Polyline>{};

    // Ticket location marker
    final ticketLat = double.tryParse(widget.ticketLatitude.toString()) ?? 0;
    final ticketLng = double.tryParse(widget.ticketLongitude.toString()) ?? 0;
    
    if (ticketLat != 0 && ticketLng != 0) {
      markers.add(
        Marker(
          markerId: const MarkerId('ticket_location'),
          position: LatLng(ticketLat, ticketLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Issue location',
          ),
        ),
      );
    }

    // Driver location marker
    if (_driverLocation != null && 
        _driverLocation!.latitude != 0 && 
        _driverLocation!.longitude != 0) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver_location'),
          position: LatLng(
            _driverLocation!.latitude,
            _driverLocation!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Driver: ${_driverLocation!.name}',
            snippet: 'Live location',
          ),
        ),
      );

      // Draw polyline between ticket and driver locations
      if (ticketLat != 0 && ticketLng != 0) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [
              LatLng(ticketLat, ticketLng),
              LatLng(_driverLocation!.latitude, _driverLocation!.longitude),
            ],
            color: Colors.blue,
            width: 3,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });

    // Update camera to show both markers
    if (markers.length >= 2) {
      _fitBoundsToMarkers();
    } else if (markers.isNotEmpty) {
      _moveCameraToMarker(markers.first.position);
    }
  }

  Future<void> _fitBoundsToMarkers() async {
    if (_markers.isEmpty) return;

    final controller = await _mapController.future;
    final bounds = _calculateBounds(_markers.map((m) => m.position).toList());
    
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _moveCameraToMarker(LatLng position) async {
    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(position, 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Default location if no valid coordinates
    final defaultLat = double.tryParse(widget.ticketLatitude.toString()) ?? 11.6994;
    final defaultLng = double.tryParse(widget.ticketLongitude.toString()) ?? 76.0773;
    final initialPosition = LatLng(defaultLat, defaultLng);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Driver Location',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: _isLoading ? Colors.grey : AppColors.textColor,
            ),
            onPressed: _isLoading ? null : () => _fetchDriverLocation(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 13,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
              // Wait a bit for map to render, then update markers
              Future.delayed(const Duration(milliseconds: 500), () {
                _updateMapMarkers();
              });
            },
          ),

          // Loading indicator
          if (_isLoading && _driverLocation == null)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Error message
          if (_errorMessage != null && _driverLocation == null)
            Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _fetchDriverLocation(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),

          // Driver info card
          if (_driverLocation != null)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _driverLocation!.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Driver is on the way',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    if (_driverLocation!.lastLocationUpdatedAt != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Updated: ${_formatTime(_driverLocation!.lastLocationUpdatedAt!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }
}

