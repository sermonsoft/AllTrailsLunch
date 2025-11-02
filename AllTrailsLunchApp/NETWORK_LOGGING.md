# Network Logging Guide

## Overview

The AllTrails Lunch app includes a comprehensive network logging system that provides detailed, ordered logging for all API requests and responses. The logging system is designed to:

1. **Prevent log mixing** - Each request gets a unique ID to keep logs grouped together
2. **Thread-safe** - Uses a serial dispatch queue to ensure ordered output
3. **Configurable** - Different log levels for different needs
4. **DEBUG-only** - Automatically disabled in release builds
5. **Comprehensive** - Logs requests, responses, errors, and retries

## Architecture

### NetworkLogger

The `NetworkLogger` is a singleton class that handles all network logging:

```swift
class NetworkLogger {
    static let shared = NetworkLogger()
    
    // Thread-safe serial queue
    private let queue = DispatchQueue(label: "com.alltrails.networklogger", qos: .utility)
    
    // Auto-incrementing request counter
    private var requestCounter: Int = 0
}
```

### Request Context

Each request gets a unique context that groups all related logs:

```swift
struct RequestContext {
    let id: Int              // Unique request ID
    let startTime: Date      // For duration calculation
    let url: URL             // Request URL
    let method: String       // HTTP method
    
    var identifier: String { "[\(id)]" }  // e.g., "[1]", "[2]"
}
```

## Log Levels

The logger supports 4 log levels:

| Level | Description | Includes |
|-------|-------------|----------|
| **none** | No logging | Nothing |
| **minimal** | Basic info only | URL, status code |
| **standard** | Standard logging | URL, status, headers |
| **verbose** | Full logging | Everything including request/response bodies |

**Default**: `verbose` in DEBUG builds, `none` in release builds

## Log Format

### Request Log

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 [1] REQUEST START
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Method:    GET
📍 URL:       https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=37.7749,-122.4194&radius=1500&type=restaurant&key=***
📍 Timestamp: 2025-11-02 14:30:45.123
📋 Headers:
   Accept: application/json
   Content-Type: application/json
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Success Response Log

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ [1] RESPONSE SUCCESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Status:    200 OK
📍 Duration:  0.234s
📍 URL:       https://maps.googleapis.com/maps/api/place/nearbysearch/json?...
📍 Size:      15.2 KB
📋 Headers:
   Content-Type: application/json; charset=UTF-8
   Date: Sat, 02 Nov 2025 14:30:45 GMT
📦 Response Body (15.2 KB):
{
  "results": [
    {
      "name": "Restaurant Name",
      "rating": 4.5,
      ...
    }
  ],
  "status": "OK"
}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Error Response Log

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ [2] RESPONSE ERROR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Status:    401 Unauthorized
📍 Duration:  0.156s
📍 URL:       https://maps.googleapis.com/maps/api/place/nearbysearch/json?...
📍 Error:     Request failed with status 401: Invalid API key
📍 Domain:    PlacesError
📍 Code:      401
📦 Response Body (234 bytes):
{
  "error_message": "The provided API key is invalid.",
  "status": "REQUEST_DENIED"
}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Retry Log

```
⚠️ [3] RETRY #1 after 1.00s (elapsed: 1.234s)
```

## Usage

### Automatic Logging

The logging is **automatically integrated** into `PlacesClient`. No manual logging calls are needed:

```swift
// This automatically logs the request and response
let response: NearbySearchResponse = try await placesClient.execute(request)
```

### Log Flow

1. **Request Start**: Logged when `execute()` is called
2. **Retry** (if needed): Logged before each retry attempt
3. **Response**: Logged when response is received (success or error)

### Example Flow

```swift
// User searches for restaurants
let (places, nextToken) = try await repository.searchNearby(
    latitude: 37.7749,
    longitude: -122.4194
)
```

**Console Output:**

```
🚀 [1] REQUEST START
📍 Method:    GET
📍 URL:       https://maps.googleapis.com/maps/api/place/nearbysearch/json?...
...

✅ [1] RESPONSE SUCCESS
📍 Status:    200 OK
📍 Duration:  0.234s
...
```

## Features

### 1. Request Ordering

Each request gets a unique ID `[1]`, `[2]`, `[3]`, etc. This ensures you can track which logs belong to which request, even when multiple requests are in flight:

```
🚀 [1] REQUEST START - Nearby search
🚀 [2] REQUEST START - Text search
✅ [1] RESPONSE SUCCESS - Nearby search (0.234s)
✅ [2] RESPONSE SUCCESS - Text search (0.456s)
```

### 2. Thread Safety

All logging operations are serialized through a dedicated queue, preventing log interleaving:

```swift
private let queue = DispatchQueue(label: "com.alltrails.networklogger", qos: .utility)
```

### 3. Sensitive Data Masking

API keys and other sensitive headers are automatically masked:

```
📋 Headers:
   Authorization: ***REDACTED***
   X-API-Key: ***REDACTED***
   Content-Type: application/json
```

### 4. Large Response Truncation

Very large responses are automatically truncated to prevent console overflow:

```
📦 Response Body (1.2 MB):
{
  "results": [
    ...
  ]
}
... (1234 more lines truncated)
```

### 5. Duration Tracking

Each request tracks its duration from start to completion:

```
📍 Duration:  0.234s
```

### 6. Retry Tracking

Retry attempts are logged with attempt number and delay:

```
⚠️ [1] RETRY #1 after 1.00s (elapsed: 1.234s)
⚠️ [1] RETRY #2 after 2.00s (elapsed: 3.456s)
```

## Configuration

### Changing Log Level

Edit `NetworkLogger.swift`:

```swift
private init() {
    #if DEBUG
    self.isEnabled = true
    self.logLevel = .verbose  // Change to .standard or .minimal
    #else
    self.isEnabled = false
    self.logLevel = .none
    #endif
}
```

### Disabling Logging in DEBUG

```swift
private init() {
    #if DEBUG
    self.isEnabled = false  // Disable even in DEBUG
    self.logLevel = .none
    #else
    self.isEnabled = false
    self.logLevel = .none
    #endif
}
```

## Debugging Tips

### 1. Filter by Request ID

In Xcode console, filter by request ID to see all logs for a specific request:

```
Filter: [1]
```

### 2. Filter by Log Type

Filter by emoji to see specific log types:

```
Filter: 🚀  (requests only)
Filter: ✅  (successful responses only)
Filter: ❌  (errors only)
Filter: ⚠️  (retries only)
```

### 3. Search for Specific URLs

```
Filter: nearbysearch
Filter: textsearch
Filter: details
```

### 4. Track Performance

Look for duration in logs:

```
Filter: Duration:
```

## Example Scenarios

### Scenario 1: Successful Search

```
🚀 [1] REQUEST START
📍 Method:    GET
📍 URL:       https://maps.googleapis.com/maps/api/place/nearbysearch/json?...
📍 Timestamp: 2025-11-02 14:30:45.123

✅ [1] RESPONSE SUCCESS
📍 Status:    200 OK
📍 Duration:  0.234s
📍 Size:      15.2 KB
```

### Scenario 2: Failed Request with Retry

```
🚀 [1] REQUEST START
📍 Method:    GET
📍 URL:       https://maps.googleapis.com/maps/api/place/nearbysearch/json?...

⚠️ [1] RETRY #1 after 1.00s (elapsed: 1.234s)

⚠️ [1] RETRY #2 after 2.00s (elapsed: 3.456s)

❌ [1] RESPONSE ERROR
📍 Status:    500 Internal Server Error
📍 Duration:  7.890s
📍 Error:     Server error
```

### Scenario 3: Multiple Concurrent Requests

```
🚀 [1] REQUEST START - Nearby search
🚀 [2] REQUEST START - Place details
🚀 [3] REQUEST START - Text search

✅ [2] RESPONSE SUCCESS (0.123s) - Place details
✅ [1] RESPONSE SUCCESS (0.234s) - Nearby search
✅ [3] RESPONSE SUCCESS (0.456s) - Text search
```

## Best Practices

1. **Use verbose logging during development** - See full request/response bodies
2. **Switch to standard for QA** - Reduce noise while keeping important info
3. **Always use none in production** - Logging is disabled by default in release builds
4. **Filter by request ID** - Track specific requests through their lifecycle
5. **Monitor durations** - Identify slow API calls
6. **Check retry patterns** - Identify flaky network conditions

## Integration

The logging is already integrated into:

- ✅ `PlacesClient.execute()` - All API requests
- ✅ Retry logic - Automatic retry logging
- ✅ Error handling - Comprehensive error logging
- ✅ Success responses - Response body logging

No additional integration needed!

## Files

- **NetworkLogger.swift** - Main logging implementation
- **PlacesClient.swift** - Integration point
- **NETWORK_LOGGING.md** - This documentation

## Summary

The network logging system provides:

- ✅ **Ordered logs** - Unique request IDs prevent mixing
- ✅ **Thread-safe** - Serial queue ensures proper ordering
- ✅ **Comprehensive** - Logs requests, responses, errors, retries
- ✅ **Configurable** - Multiple log levels
- ✅ **Secure** - Masks sensitive data
- ✅ **DEBUG-only** - Automatically disabled in release
- ✅ **Zero-config** - Works automatically with PlacesClient

Happy debugging! 🐛🔍

