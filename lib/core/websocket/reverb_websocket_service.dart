import 'dart:async';
import 'dart:convert';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../network/api_config.dart';
import '../storage/token_storage.dart';

/// Service for managing Reverb WebSocket connections
/// Handles real-time driver location updates via Laravel Reverb
class ReverbWebSocketService {
  static ReverbWebSocketService? _instance;
  PusherChannelsFlutter? _pusher;
  String? _currentChannelName;
  StreamController<DriverLocationEvent>? _locationStreamController;
  bool _isConnected = false;
  bool _isSubscribed = false;

  ReverbWebSocketService._();

  static ReverbWebSocketService get instance {
    _instance ??= ReverbWebSocketService._();
    return _instance!;
  }

  /// Stream for driver location updates
  Stream<DriverLocationEvent> get locationStream {
    _locationStreamController ??= StreamController<DriverLocationEvent>.broadcast();
    return _locationStreamController!.stream;
  }

  /// Initialize and connect to Reverb WebSocket server
  Future<void> initialize({required int customerId}) async {
    try {
      final token = await TokenStorage.readToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      print('🔵 [ReverbWebSocket] Initializing connection...');
      print('🔵 [ReverbWebSocket] Customer ID: $customerId');
      print('🔵 [ReverbWebSocket] Reverb URL: ${ApiConfig.reverbWsUrl}');

      _pusher = PusherChannelsFlutter.getInstance();

      // Initialize Pusher with basic configuration
      // Note: Auth will be handled during channel subscription
      await _pusher!.init(
        apiKey: ApiConfig.reverbAppKey,
        cluster: 'mt1', // Default cluster, Reverb doesn't use this but required
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onSubscriptionSucceeded: (String channelName, dynamic data) {
          _onSubscriptionSucceeded(channelName);
        },
        onEvent: _onEvent,
        onSubscriptionError: (String message, dynamic error) {
          _onSubscriptionError(message, error);
        },
        onDecryptionFailure: (String event, String reason) => _onDecryptionFailure(event, reason),
        onMemberAdded: _onMemberAdded,
        onMemberRemoved: _onMemberRemoved,
      );

      await _pusher!.connect();

      // Subscribe to customer's private channel
      final channelName = 'private-customer.$customerId.driver-location';
      print('🔵 [ReverbWebSocket] Subscribing to channel: $channelName');
      await _pusher!.subscribe(channelName: channelName);
      _currentChannelName = channelName;

      print('✅ [ReverbWebSocket] Connection initialized successfully');
    } catch (e) {
      print('❌ [ReverbWebSocket] Error initializing: $e');
      rethrow;
    }
  }

  /// Subscribe to driver location updates for a specific ticket
  void subscribeToTicket(int ticketId) {
    print('🔵 [ReverbWebSocket] Subscribed to ticket: $ticketId');
    // The channel is already subscribed, events will be filtered by ticket_id
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    try {
      if (_currentChannelName != null) {
        print('🔵 [ReverbWebSocket] Unsubscribing from channel: $_currentChannelName');
        await _pusher?.unsubscribe(channelName: _currentChannelName!);
        _currentChannelName = null;
      }

      print('🔵 [ReverbWebSocket] Disconnecting...');
      await _pusher?.disconnect();
      _isConnected = false;
      _isSubscribed = false;
      print('✅ [ReverbWebSocket] Disconnected successfully');
    } catch (e) {
      print('❌ [ReverbWebSocket] Error disconnecting: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _locationStreamController?.close();
    _locationStreamController = null;
  }

  // Event Handlers

  void _onConnectionStateChange(dynamic currentState, dynamic previousState) {
    print('🔵 [ReverbWebSocket] Connection state changed: $previousState -> $currentState');
    _isConnected = currentState == 'CONNECTED';
  }

  void _onError(String message, int? code, dynamic error) {
    print('❌ [ReverbWebSocket] Error: $message');
    if (code != null) {
      print('❌ [ReverbWebSocket] Error code: $code');
    }
    if (error != null) {
      print('❌ [ReverbWebSocket] Error details: $error');
    }
  }

  void _onSubscriptionSucceeded(String channelName) {
    print('✅ [ReverbWebSocket] Subscribed to channel: $channelName');
    _isSubscribed = true;
  }

  void _onEvent(PusherEvent event) {
    print('🔵 [ReverbWebSocket] Event received: ${event.eventName}');
    print('🔵 [ReverbWebSocket] Channel: ${event.channelName}');
    print('🔵 [ReverbWebSocket] Data: ${event.data}');

    if (event.eventName == 'driver.location.updated') {
      try {
        final data = jsonDecode(event.data) as Map<String, dynamic>;
        final locationEvent = DriverLocationEvent.fromJson(data);
        
        print('✅ [ReverbWebSocket] Driver location updated:');
        print('   Ticket ID: ${locationEvent.ticketId}');
        print('   Driver: ${locationEvent.driverName}');
        print('   Location: ${locationEvent.latitude}, ${locationEvent.longitude}');

        _locationStreamController?.add(locationEvent);
      } catch (e) {
        print('❌ [ReverbWebSocket] Error parsing location event: $e');
      }
    }
  }

  void _onSubscriptionError(String message, dynamic error) {
    print('❌ [ReverbWebSocket] Subscription error: $message');
    if (error != null) {
      print('❌ [ReverbWebSocket] Error details: $error');
    }
  }

  void _onDecryptionFailure(String event, String reason) {
    print('❌ [ReverbWebSocket] Decryption failure: $event - $reason');
  }

  void _onMemberAdded(String channelName, PusherMember member) {
    print('🔵 [ReverbWebSocket] Member added to $channelName: ${member.userId}');
  }

  void _onMemberRemoved(String channelName, PusherMember member) {
    print('🔵 [ReverbWebSocket] Member removed from $channelName: ${member.userId}');
  }

  /// Check if connected
  bool get isConnected => _isConnected && _isSubscribed;
}

/// Driver location event data model
class DriverLocationEvent {
  final int ticketId;
  final int driverId;
  final String driverName;
  final double latitude;
  final double longitude;
  final DateTime? lastLocationUpdatedAt;

  DriverLocationEvent({
    required this.ticketId,
    required this.driverId,
    required this.driverName,
    required this.latitude,
    required this.longitude,
    this.lastLocationUpdatedAt,
  });

  factory DriverLocationEvent.fromJson(Map<String, dynamic> json) {
    double lat = 0;
    double lng = 0;

    // Handle latitude - can be string or number
    if (json['latitude'] != null) {
      if (json['latitude'] is num) {
        lat = (json['latitude'] as num).toDouble();
      } else if (json['latitude'] is String) {
        lat = double.tryParse(json['latitude'] as String) ?? 0;
      }
    }

    // Handle longitude - can be string or number
    if (json['longitude'] != null) {
      if (json['longitude'] is num) {
        lng = (json['longitude'] as num).toDouble();
      } else if (json['longitude'] is String) {
        lng = double.tryParse(json['longitude'] as String) ?? 0;
      }
    }

    return DriverLocationEvent(
      ticketId: (json['ticket_id'] as num?)?.toInt() ?? 0,
      driverId: (json['driver_id'] as num?)?.toInt() ?? 0,
      driverName: json['driver_name'] as String? ?? '',
      latitude: lat,
      longitude: lng,
      lastLocationUpdatedAt: json['last_location_updated_at'] != null
          ? DateTime.tryParse(json['last_location_updated_at'] as String)
          : null,
    );
  }
}

