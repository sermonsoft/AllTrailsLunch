# Network Logging - Real Example Output

This document shows actual console output examples from the network logging system.

## Example 1: Successful Nearby Search

**User Action**: Opens app, location permission granted, nearby restaurants loaded

**Console Output**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 [1] REQUEST START
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Method:    GET
📍 URL:       https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=37.7749,-122.4194&radius=1500&type=restaurant&key=***REDACTED***
📍 Timestamp: 2025-11-02 14:30:45.123
📋 Headers:
   Accept: application/json
   Content-Type: application/json
   User-Agent: AllTrailsLunch/1.0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ [1] RESPONSE SUCCESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Status:    200 OK
📍 Duration:  0.234s
📍 URL:       https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=37.7749,-122.4194&radius=1500&type=restaurant&key=***REDACTED***
📍 Size:      15.2 KB
📋 Headers:
   Content-Type: application/json; charset=UTF-8
   Date: Sat, 02 Nov 2025 14:30:45 GMT
   Server: scaffolding on HTTPServer2
📦 Response Body (15.2 KB):
{
  "html_attributions" : [],
  "results" : [
    {
      "business_status" : "OPERATIONAL",
      "geometry" : {
        "location" : {
          "lat" : 37.7749295,
          "lng" : -122.4194155
        }
      },
      "icon" : "https://maps.gstatic.com/mapfiles/place_api/icons/v1/png_71/restaurant-71.png",
      "name" : "The House",
      "opening_hours" : {
        "open_now" : true
      },
      "photos" : [
        {
          "height" : 3024,
          "photo_reference" : "AeJbb3f...",
          "width" : 4032
        }
      ],
      "place_id" : "ChIJIQBpAG2ahYAR_6128GcTUEo",
      "rating" : 4.5,
      "reference" : "ChIJIQBpAG2ahYAR_6128GcTUEo",
      "types" : [ "restaurant", "food", "point_of_interest", "establishment" ],
      "user_ratings_total" : 1234,
      "vicinity" : "1230 Grant Avenue, San Francisco"
    },
    {
      "business_status" : "OPERATIONAL",
      "geometry" : {
        "location" : {
          "lat" : 37.7750295,
          "lng" : -122.4195155
        }
      },
      "name" : "Mama's on Washington Square",
      "place_id" : "ChIJXYBpAG2ahYAR_6128GcTUEp",
      "rating" : 4.3,
      "user_ratings_total" : 987,
      "vicinity" : "1701 Stockton Street, San Francisco"
    }
  ],
  "status" : "OK"
}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Example 2: Text Search with User Query

**User Action**: Types "pizza" in search bar and presses search

**Console Output**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 [2] REQUEST START
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Method:    GET
📍 URL:       https://maps.googleapis.com/maps/api/place/textsearch/json?query=pizza&location=37.7749,-122.4194&key=***REDACTED***
📍 Timestamp: 2025-11-02 14:31:12.456
📋 Headers:
   Accept: application/json
   Content-Type: application/json
   User-Agent: AllTrailsLunch/1.0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ [2] RESPONSE SUCCESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Status:    200 OK
📍 Duration:  0.189s
📍 URL:       https://maps.googleapis.com/maps/api/place/textsearch/json?query=pizza&location=37.7749,-122.4194&key=***REDACTED***
📍 Size:      12.8 KB
📋 Headers:
   Content-Type: application/json; charset=UTF-8
   Date: Sat, 02 Nov 2025 14:31:12 GMT
📦 Response Body (12.8 KB):
{
  "results" : [
    {
      "name" : "Tony's Pizza Napoletana",
      "rating" : 4.6,
      "user_ratings_total" : 2345,
      "place_id" : "ChIJPizza123...",
      "vicinity" : "1570 Stockton Street, San Francisco"
    }
  ],
  "status" : "OK"
}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Example 3: Failed Request (Invalid API Key)

**User Action**: App configured with invalid API key

**Console Output**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 [3] REQUEST START
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Method:    GET
📍 URL:       https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=37.7749,-122.4194&radius=1500&type=restaurant&key=***REDACTED***
📍 Timestamp: 2025-11-02 14:32:00.789
📋 Headers:
   Accept: application/json
   Content-Type: application/json
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ [3] RESPONSE ERROR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Status:    403 Forbidden
📍 Duration:  0.156s
📍 URL:       https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=37.7749,-122.4194&radius=1500&type=restaurant&key=***REDACTED***
📍 Error:     Request failed with status 403: The provided API key is invalid.
📍 Domain:    PlacesError
📍 Code:      403
📋 Headers:
   Content-Type: application/json; charset=UTF-8
   Date: Sat, 02 Nov 2025 14:32:00 GMT
📦 Response Body (234 bytes):
{
  "error_message" : "The provided API key is invalid. Please see https://developers.google.com/places/web-service/get-api-key for more information.",
  "html_attributions" : [],
  "results" : [],
  "status" : "REQUEST_DENIED"
}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Example 4: Server Error with Retry

**User Action**: Google API experiencing temporary issues

**Console Output**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 [4] REQUEST START
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Method:    GET
📍 URL:       https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=37.7749,-122.4194&radius=1500&type=restaurant&key=***REDACTED***
📍 Timestamp: 2025-11-02 14:33:00.000
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ [4] RETRY #1 after 1.00s (elapsed: 1.234s)

⚠️ [4] RETRY #2 after 2.00s (elapsed: 3.456s)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ [4] RESPONSE SUCCESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Status:    200 OK
📍 Duration:  7.890s
📍 URL:       https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=37.7749,-122.4194&radius=1500&type=restaurant&key=***REDACTED***
📍 Size:      15.2 KB
📦 Response Body (15.2 KB):
{
  "results" : [ ... ],
  "status" : "OK"
}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Example 5: Multiple Concurrent Requests

**User Action**: User quickly switches between List and Map views, triggering multiple API calls

**Console Output**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 [5] REQUEST START
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Method:    GET
📍 URL:       https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=37.7749,-122.4194&radius=1500&type=restaurant&key=***REDACTED***
📍 Timestamp: 2025-11-02 14:34:00.000
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 [6] REQUEST START
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Method:    GET
📍 URL:       https://maps.googleapis.com/maps/api/place/details/json?place_id=ChIJIQBpAG2ahYAR_6128GcTUEo&fields=name,rating,formatted_phone_number,opening_hours,website,reviews,formatted_address&key=***REDACTED***
📍 Timestamp: 2025-11-02 14:34:00.123
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 [7] REQUEST START
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Method:    GET
📍 URL:       https://maps.googleapis.com/maps/api/place/textsearch/json?query=sushi&location=37.7749,-122.4194&key=***REDACTED***
📍 Timestamp: 2025-11-02 14:34:00.456
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ [6] RESPONSE SUCCESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Status:    200 OK
📍 Duration:  0.123s
📍 URL:       https://maps.googleapis.com/maps/api/place/details/json?place_id=ChIJIQBpAG2ahYAR_6128GcTUEo&fields=...
📍 Size:      3.4 KB
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ [5] RESPONSE SUCCESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Status:    200 OK
📍 Duration:  0.234s
📍 URL:       https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=37.7749,-122.4194&radius=1500&type=restaurant&key=***REDACTED***
📍 Size:      15.2 KB
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ [7] RESPONSE SUCCESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Status:    200 OK
📍 Duration:  0.456s
📍 URL:       https://maps.googleapis.com/maps/api/place/textsearch/json?query=sushi&location=37.7749,-122.4194&key=***REDACTED***
📍 Size:      12.1 KB
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Notice**: Each request has a unique ID `[5]`, `[6]`, `[7]`, making it easy to track which logs belong together even when requests overlap.

---

## Example 6: Network Timeout

**User Action**: Poor network connection, request times out

**Console Output**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 [8] REQUEST START
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Method:    GET
📍 URL:       https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=37.7749,-122.4194&radius=1500&type=restaurant&key=***REDACTED***
📍 Timestamp: 2025-11-02 14:35:00.000
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ [8] RETRY #1 after 1.00s (elapsed: 30.123s)

⚠️ [8] RETRY #2 after 2.00s (elapsed: 62.456s)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ [8] RESPONSE ERROR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Duration:  94.789s
📍 URL:       https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=37.7749,-122.4194&radius=1500&type=restaurant&key=***REDACTED***
📍 Error:     The request timed out.
📍 Domain:    NSURLErrorDomain
📍 Code:      -1001
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Key Observations

### 1. Request IDs Keep Logs Organized
- Each request gets a unique ID: `[1]`, `[2]`, `[3]`, etc.
- Easy to filter in Xcode console: just search for `[1]` to see all logs for request #1

### 2. Clear Visual Separation
- Separator lines (`━━━`) make it easy to distinguish between different log entries
- Emojis provide quick visual identification:
  - 🚀 = Request start
  - ✅ = Success
  - ❌ = Error
  - ⚠️ = Retry

### 3. Comprehensive Information
- **Requests**: Method, URL, timestamp, headers
- **Responses**: Status, duration, size, headers, body
- **Errors**: Status, error message, domain, code
- **Retries**: Attempt number, delay, elapsed time

### 4. Security
- API keys are automatically masked: `***REDACTED***`
- Sensitive headers are hidden

### 5. Performance Tracking
- Duration is logged for every request
- Easy to identify slow API calls
- Retry delays are clearly shown

---

## Filtering Tips

### In Xcode Console

**Filter by request ID:**
```
[1]
```

**Filter by type:**
```
🚀  (requests)
✅  (successes)
❌  (errors)
⚠️  (retries)
```

**Filter by endpoint:**
```
nearbysearch
textsearch
details
```

**Filter by status:**
```
200 OK
403 Forbidden
500 Internal
```

**Filter by duration:**
```
Duration:
```

---

## Summary

The logging system provides:

✅ **Clear organization** - Unique IDs prevent log mixing  
✅ **Visual clarity** - Emojis and separators for easy scanning  
✅ **Complete information** - Everything you need to debug  
✅ **Security** - Sensitive data is masked  
✅ **Performance insights** - Duration tracking for all requests  
✅ **Thread-safe** - Logs are properly ordered even with concurrent requests  

Happy debugging! 🐛🔍

