# WebSocket Implementation - Real-Time Driver Location Tracking

## Overview

This document describes the implementation of real-time driver location tracking using Laravel Reverb WebSocket server. The implementation provides instant location updates to customers when drivers update their location, eliminating the need for constant polling.

## Implementation Details

### 1. Dependencies Added

**Package:** `pusher_channels_flutter: ^2.2.1`

This package provides WebSocket connectivity compatible with Laravel Reverb (which uses the Pusher protocol).

**Location:** `pubspec.yaml`

```yaml
dependencies:
  pusher_channels_flutter: ^2.2.1
```

### 2. Configuration

**File:** `lib/core/network/api_config.dart`

Added Reverb WebSocket configuration constants:

```dart
// Reverb WebSocket Configuration
static const String reverbAppId = '955186';
static const String reverbAppKey = 'x4bc0hkyw8jbwhpa5koi';
static const String reverbAppSecret = 'lnw6wfgtmuilz21srsiy';
static const String reverbHost = 'onecharge.io';
static const String reverbPort = '8080';
static const String reverbScheme = 'https';
static const String reverbAuthEndpoint = '/broadcasting/auth';

// Reverb WebSocket URLs
static String get reverbWsUrl => '$reverbScheme://$reverbHost:$reverbPort';
static String get reverbAuthUrl => '$baseUrl$reverbAuthEndpoint';
```

### 3. WebSocket Service

**File:** `lib/core/websocket/reverb_websocket_service.dart`

A singleton service that manages WebSocket connections and handles real-time driver location updates.

#### Key Features:

- **Singleton Pattern:** Ensures only one WebSocket connection is active
- **Automatic Authentication:** Uses stored authentication token for channel authorization
- **Event Streaming:** Provides a stream of driver location events
- **Error Handling:** Comprehensive error handling with fallback mechanisms
- **Connection Management:** Handles connection, subscription, and disconnection

#### Usage:

```dart
// Get service instance
final websocketService = ReverbWebSocketService.instance;

// Initialize connection (requires customer ID)
await websocketService.initialize(customerId: customerId);

// Listen to location updates
websocketService.locationStream.listen((event) {
  // Handle driver location update
  print('Driver location: ${event.latitude}, ${event.longitude}');
});

// Disconnect when done
await websocketService.disconnect();
```

#### Channel Structure:

- **Channel Name:** `private-customer.{customerId}.driver-location`
- **Event Name:** `driver.location.updated`
- **Event Data:**
  ```json
  {
    "ticket_id": 1,
    "driver_id": 5,
    "driver_name": "Driver Name",
    "latitude": 40.7580,
    "longitude": -73.9855,
    "last_location_updated_at": "2025-12-17T10:30:00Z"
  }
  ```

### 4. Integration with Driver Location Map Screen

**File:** `lib/screen/issue_report/driver_location_map_screen.dart`

The driver location map screen now uses WebSocket for real-time updates with automatic fallback to polling if WebSocket fails.

#### Implementation Details:

1. **WebSocket Initialization:**
   - Retrieves customer ID from stored user data
   - Initializes WebSocket connection on screen load
   - Subscribes to location update events

2. **Real-Time Updates:**
   - Listens to WebSocket stream for location events
   - Filters events by ticket ID to show only relevant updates
   - Updates map markers and polylines automatically

3. **Fallback Mechanism:**
   - If WebSocket fails, automatically falls back to REST API polling
   - Polling interval: 30 seconds (reduced from 10 seconds when WebSocket is active)
   - Seamless transition between WebSocket and polling

4. **Connection Management:**
   - WebSocket connection is maintained while screen is active
   - Subscription is cancelled when screen is disposed
   - Connection can be reused by other screens

### 5. Data Models

**File:** `lib/core/websocket/reverb_websocket_service.dart`

#### DriverLocationEvent Model:

```dart
class DriverLocationEvent {
  final int ticketId;
  final int driverId;
  final String driverName;
  final double latitude;
  final double longitude;
  final DateTime? lastLocationUpdatedAt;
}
```

This model represents a driver location update event received via WebSocket.

## How It Works

### Connection Flow:

1. **Initialization:**
   - User opens driver location map screen
   - App retrieves customer ID from stored user data
   - WebSocket service initializes connection to Reverb server
   - Authenticates using Bearer token
   - Subscribes to private channel: `private-customer.{customerId}.driver-location`

2. **Real-Time Updates:**
   - Driver app updates location via REST API
   - Backend broadcasts event to customer's private channel
   - WebSocket service receives event
   - Event is parsed and added to stream
   - Map screen updates driver marker and route

3. **Error Handling:**
   - If WebSocket connection fails, falls back to REST API polling
   - Connection errors are logged for debugging
   - User experience remains smooth with automatic fallback

### Channel Authentication:

The WebSocket service automatically includes the authentication token in the connection headers:

```dart
authHeaders: {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
  'Accept': 'application/json',
}
```

The backend validates this token at `/broadcasting/auth` endpoint before allowing channel subscription.

## API Endpoints Used

### WebSocket:
- **Connection URL:** `wss://onecharge.io:8080`
- **Auth Endpoint:** `https://onecharge.io/broadcasting/auth`
- **Channel:** `private-customer.{customerId}.driver-location`
- **Event:** `driver.location.updated`

### REST API (Fallback):
- **Endpoint:** `GET /api/customer/location/tickets/{ticketId}/driver`
- **Used when:** WebSocket connection fails or is unavailable

## Benefits

1. **Real-Time Updates:** Instant location updates without polling delays
2. **Reduced Server Load:** No constant polling requests
3. **Better User Experience:** Smooth, real-time map updates
4. **Automatic Fallback:** Seamless transition to polling if WebSocket fails
5. **Efficient:** Single WebSocket connection can handle multiple tickets

## Testing

### Test WebSocket Connection:

1. Open driver location map screen
2. Check console logs for WebSocket initialization messages
3. Verify connection status in logs
4. Update driver location from driver app
5. Verify map updates in real-time

### Test Fallback Mechanism:

1. Disable WebSocket connection (simulate network issue)
2. Verify automatic fallback to REST API polling
3. Check that location updates continue via polling

## Troubleshooting

### WebSocket Not Connecting:

1. **Check Authentication Token:**
   - Verify token is stored correctly
   - Ensure token is not expired
   - Check token format in logs

2. **Check Network:**
   - Verify Reverb server is accessible
   - Check firewall/network restrictions
   - Verify SSL certificate validity

3. **Check Configuration:**
   - Verify Reverb credentials in `ApiConfig`
   - Check channel name format
   - Verify auth endpoint URL

### Location Updates Not Received:

1. **Check Channel Subscription:**
   - Verify customer ID is correct
   - Check channel name matches backend
   - Verify event name is correct

2. **Check Backend:**
   - Verify driver location updates are being broadcast
   - Check backend logs for broadcast events
   - Verify ticket ID matches

## Future Enhancements

1. **Connection Retry Logic:** Automatic reconnection on connection loss
2. **Connection Status Indicator:** Show WebSocket connection status in UI
3. **Multiple Ticket Support:** Handle multiple active tickets simultaneously
4. **Presence Channels:** Show when driver is online/offline
5. **Message Broadcasting:** Support for driver-customer messaging

## Files Modified/Created

### Created:
- `lib/core/websocket/reverb_websocket_service.dart` - WebSocket service
- `WEBSOCKET_IMPLEMENTATION.md` - This documentation

### Modified:
- `pubspec.yaml` - Added `pusher_channels_flutter` package
- `lib/core/network/api_config.dart` - Added Reverb configuration
- `lib/screen/issue_report/driver_location_map_screen.dart` - Integrated WebSocket

## Configuration Summary

| Setting | Value |
|---------|-------|
| Reverb App ID | 955186 |
| Reverb App Key | x4bc0hkyw8jbwhpa5koi |
| Reverb Host | onecharge.io |
| Reverb Port | 8080 |
| Reverb Scheme | https |
| Auth Endpoint | /broadcasting/auth |
| Channel Pattern | private-customer.{customerId}.driver-location |
| Event Name | driver.location.updated |

## Notes

- WebSocket connection is maintained as a singleton to allow reuse across screens
- The service automatically handles authentication using stored tokens
- Fallback to REST API polling ensures location updates continue even if WebSocket fails
- Connection is not automatically disconnected when leaving the map screen to allow reuse
- Customer ID is retrieved from stored user data (UserStorage)

---

**Last Updated:** December 2024  
**Version:** 1.0.0

