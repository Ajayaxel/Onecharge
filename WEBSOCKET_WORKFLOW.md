# WebSocket Real-Time Driver Location Tracking - Workflow

## Overview

This document explains the complete workflow of how real-time driver location tracking works using Laravel Reverb WebSocket server in the OneCharge customer mobile application.

## Architecture Diagram

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│  Driver App     │         │  Backend Server │         │  Customer App   │
│                 │         │  (Laravel)      │         │  (Flutter)      │
└────────┬────────┘         └────────┬────────┘         └────────┬────────┘
         │                           │                           │
         │ 1. Update Location       │                           │
         │    POST /api/driver/     │                           │
         │    location/update       │                           │
         ├─────────────────────────>│                           │
         │                           │                           │
         │                           │ 2. Broadcast Event        │
         │                           │    to Reverb              │
         │                           ├───────────────────────────┼─────────┐
         │                           │                           │         │
         │                           │ 3. Reverb WebSocket       │         │
         │                           │    Server                 │         │
         │                           │    (Port 8080)           │         │
         │                           │                           │         │
         │                           │ 4. Push to Channel        │         │
         │                           │    private-customer.     │         │
         │                           │    {id}.driver-location  │         │
         │                           │                           │         │
         │                           │ 5. Event:                │         │
         │                           │    driver.location.      │         │
         │                           │    updated               │         │
         │                           │<──────────────────────────┼─────────┘
         │                           │                           │
         │                           │                           │ 6. Update Map
         │                           │                           │    Marker
```

## Complete Workflow

### Phase 1: Initial Setup

#### Step 1.1: Customer Opens Driver Location Map
```
Customer App Flow:
1. User navigates to Issue Status screen
2. If driver is assigned AND ticket is not completed:
   - Map icon appears in AppBar
3. User taps map icon
4. DriverLocationMapScreen opens
```

#### Step 1.2: WebSocket Service Initialization
```
Location: lib/screen/issue_report/driver_location_map_screen.dart

1. Screen's initState() is called
2. _initializeWebSocket() method is invoked
3. Retrieves customer ID from UserStorage
4. Gets ReverbWebSocketService singleton instance
5. Calls websocketService.initialize(customerId: customerId)
```

#### Step 1.3: WebSocket Connection Establishment
```
Location: lib/core/websocket/reverb_websocket_service.dart

1. Retrieves authentication token from TokenStorage
2. Initializes PusherChannelsFlutter instance
3. Configures connection parameters:
   - API Key: x4bc0hkyw8jbwhpa5koi
   - Host: onecharge.io
   - Port: 8080
   - Scheme: https
4. Sets up event handlers:
   - onConnectionStateChange
   - onError
   - onEvent
   - onSubscriptionSucceeded
   - etc.
5. Calls pusher.connect()
6. WebSocket connection established to wss://onecharge.io:8080
```

#### Step 1.4: Channel Subscription
```
1. Constructs channel name: private-customer.{customerId}.driver-location
   Example: private-customer.123.driver-location

2. Calls pusher.subscribe(channelName: channelName)

3. For private channels, Pusher automatically:
   - Sends auth request to: https://onecharge.io/broadcasting/auth
   - Includes Bearer token in Authorization header
   - Backend validates token and returns channel auth signature

4. Subscription confirmed
5. onSubscriptionSucceeded callback fired
6. _isSubscribed = true
```

#### Step 1.5: Stream Subscription Setup
```
Location: lib/screen/issue_report/driver_location_map_screen.dart

1. Subscribes to websocketService.locationStream
2. Listens for DriverLocationEvent objects
3. Filters events by ticketId to show only relevant updates
4. Sets up error handler for fallback to REST API
```

### Phase 2: Real-Time Location Updates

#### Step 2.1: Driver Updates Location
```
Driver App Flow:
1. Driver app periodically updates location (every 10-30 seconds)
2. Makes POST request to: /api/driver/location/update
3. Sends:
   {
     "latitude": 40.7580,
     "longitude": -73.9855
   }
```

#### Step 2.2: Backend Processes Location Update
```
Backend Flow (Laravel):
1. Receives location update from driver
2. Validates and stores driver location
3. Finds all active tickets assigned to this driver
4. For each ticket:
   - Gets customer ID from ticket
   - Broadcasts event to customer's private channel
```

#### Step 2.3: Backend Broadcasts Event
```
Backend Code (Laravel):
event(new DriverLocationUpdated(
    ticketId: $ticket->id,
    driverId: $driver->id,
    driverName: $driver->name,
    latitude: $latitude,
    longitude: $longitude
));

This broadcasts to channel: private-customer.{customerId}.driver-location
With event name: driver.location.updated
```

#### Step 2.4: Reverb Server Pushes Event
```
Reverb WebSocket Server:
1. Receives broadcast event from Laravel
2. Identifies target channel: private-customer.{customerId}.driver-location
3. Finds all connected clients subscribed to this channel
4. Pushes event to all subscribers via WebSocket
```

#### Step 2.5: Customer App Receives Event
```
Location: lib/core/websocket/reverb_websocket_service.dart

1. onEvent callback is triggered
2. Event name checked: driver.location.updated
3. Event data parsed from JSON:
   {
     "ticket_id": 1,
     "driver_id": 5,
     "driver_name": "John Driver",
     "latitude": 40.7580,
     "longitude": -73.9855,
     "last_location_updated_at": "2025-12-17T10:30:00Z"
   }
4. DriverLocationEvent object created
5. Event added to locationStream
```

#### Step 2.6: Map Screen Updates
```
Location: lib/screen/issue_report/driver_location_map_screen.dart

1. Stream listener receives DriverLocationEvent
2. Checks if event.ticketId matches current ticketId
3. If match:
   - Updates _driverLocation state
   - Calls _updateMapMarkers()
   - Map automatically updates:
     * Driver marker position
     * Route polyline between driver and ticket
     * Camera position (if needed)
4. UI reflects new driver location instantly
```

### Phase 3: Fallback Mechanism

#### Step 3.1: WebSocket Connection Failure
```
Scenario: WebSocket connection fails or is unavailable

1. _initializeWebSocket() catches exception
2. Sets _useWebSocket = false
3. Logs error for debugging
4. Continues with REST API polling
```

#### Step 3.2: REST API Polling (Fallback)
```
Location: lib/screen/issue_report/driver_location_map_screen.dart

1. Timer already running (30 second interval)
2. Every 30 seconds:
   - Calls _fetchDriverLocation()
   - Makes GET request to: /api/customer/location/tickets/{ticketId}/driver
   - Receives driver location
   - Updates map markers
3. User experience remains smooth
```

### Phase 4: Connection Management

#### Step 4.1: Screen Lifecycle
```
When DriverLocationMapScreen is opened:
1. WebSocket connection initialized
2. Channel subscribed
3. Stream listener active

When DriverLocationMapScreen is closed:
1. Stream subscription cancelled
2. Timer cancelled
3. WebSocket connection remains active (for reuse)
4. Screen disposed
```

#### Step 4.2: WebSocket Service Lifecycle
```
Singleton Pattern:
- One WebSocket connection per app instance
- Connection can be reused across multiple screens
- Connection persists until explicitly disconnected

Disconnection:
- Only when app is closed or user logs out
- Or when explicitly calling websocketService.disconnect()
```

## Data Flow Example

### Example Scenario: Driver Moving to Customer Location

```
Time: 10:00:00
Driver Location: (40.7500, -73.9800)
Customer Location: (40.7128, -74.0060)

1. Driver updates location
   → Backend receives: (40.7510, -73.9790)
   → Broadcasts to customer channel
   → Customer app receives event
   → Map updates driver marker

Time: 10:00:30
Driver Location: (40.7520, -73.9780)

2. Driver updates location again
   → Backend receives: (40.7520, -73.9780)
   → Broadcasts to customer channel
   → Customer app receives event
   → Map updates driver marker
   → Route polyline updates

Time: 10:01:00
Driver Location: (40.7530, -73.9770)

3. Process continues...
   → Real-time updates every 10-30 seconds
   → Customer sees driver approaching
   → Route gets shorter as driver gets closer
```

## Event Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Driver Location Update Flow                    │
└─────────────────────────────────────────────────────────────────┘

Driver App
    │
    ├─> POST /api/driver/location/update
    │   { latitude, longitude }
    │
    ▼
Backend (Laravel)
    │
    ├─> Store location in database
    ├─> Find active tickets for driver
    │
    ▼
Broadcast Event
    │
    ├─> DriverLocationUpdated event
    │   - ticket_id
    │   - driver_id
    │   - driver_name
    │   - latitude
    │   - longitude
    │   - last_location_updated_at
    │
    ▼
Reverb WebSocket Server
    │
    ├─> Channel: private-customer.{id}.driver-location
    ├─> Event: driver.location.updated
    │
    ▼
Customer App (WebSocket)
    │
    ├─> onEvent callback triggered
    ├─> Parse event data
    ├─> Create DriverLocationEvent
    ├─> Add to locationStream
    │
    ▼
DriverLocationMapScreen
    │
    ├─> Stream listener receives event
    ├─> Filter by ticketId
    ├─> Update _driverLocation state
    ├─> Call _updateMapMarkers()
    │
    ▼
Google Maps
    │
    ├─> Update driver marker position
    ├─> Update route polyline
    ├─> Animate camera (if needed)
    │
    ▼
User sees updated driver location on map
```

## Channel and Event Structure

### Channel Naming Convention
```
Pattern: private-customer.{customerId}.driver-location

Examples:
- private-customer.1.driver-location
- private-customer.123.driver-location
- private-customer.456.driver-location
```

### Event Structure
```json
{
  "ticket_id": 1,
  "driver_id": 5,
  "driver_name": "John Driver",
  "latitude": 40.7580,
  "longitude": -73.9855,
  "last_location_updated_at": "2025-12-17T10:30:00Z"
}
```

## Error Handling Flow

```
WebSocket Connection Error
    │
    ├─> Catch exception in _initializeWebSocket()
    ├─> Set _useWebSocket = false
    ├─> Log error
    ├─> Continue with REST API polling
    │
    ▼
REST API Polling Active
    │
    ├─> Timer runs every 30 seconds
    ├─> GET /api/customer/location/tickets/{ticketId}/driver
    ├─> Update map on successful response
    │
    ▼
User still sees location updates (via polling)
```

## Performance Considerations

### WebSocket Advantages
- **Real-time:** Updates arrive instantly (no polling delay)
- **Efficient:** Single connection handles all updates
- **Low Latency:** Direct push from server to client
- **Reduced Server Load:** No constant HTTP requests

### Polling Fallback
- **Reliable:** Works even if WebSocket fails
- **Simple:** Standard HTTP requests
- **Compatible:** Works with any network setup
- **Trade-off:** 30-second delay between updates

## Security Flow

### Authentication
```
1. Customer app stores Bearer token after login
2. WebSocket service retrieves token from TokenStorage
3. When subscribing to private channel:
   - Pusher sends auth request to /broadcasting/auth
   - Includes Authorization: Bearer {token} header
4. Backend validates token
5. Backend returns channel auth signature
6. Subscription authorized
```

### Channel Privacy
```
- Private channels require authentication
- Only authenticated customers can subscribe
- Each customer has their own channel
- Events are only sent to the specific customer's channel
```

## Testing Workflow

### Test Real-Time Updates
```
1. Open driver location map screen
2. Check console for WebSocket connection logs
3. From driver app, update location
4. Verify map updates within 1-2 seconds
5. Check that route polyline updates
```

### Test Fallback
```
1. Disable WebSocket (simulate network issue)
2. Verify fallback to REST API polling
3. Check that location updates continue
4. Verify 30-second polling interval
```

### Test Multiple Tickets
```
1. Create multiple tickets with assigned drivers
2. Open driver location map for ticket 1
3. Verify only ticket 1 updates are received
4. Open driver location map for ticket 2
5. Verify only ticket 2 updates are received
```

## Summary

The workflow ensures:
1. ✅ **Instant Updates:** WebSocket provides real-time location updates
2. ✅ **Reliability:** Automatic fallback to REST API if WebSocket fails
3. ✅ **Security:** Private channels with token authentication
4. ✅ **Efficiency:** Single connection handles all updates
5. ✅ **User Experience:** Smooth, real-time map updates

The system is designed to be robust, with multiple layers of error handling and fallback mechanisms to ensure customers always see driver location updates, whether via WebSocket or REST API polling.

---

**Last Updated:** December 2024  
**Version:** 1.0.0

