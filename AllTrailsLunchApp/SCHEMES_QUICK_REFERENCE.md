# Build Schemes - Quick Reference

## TL;DR

| Scheme | Use Case | Data Source | Flag |
|--------|----------|-------------|------|
| **Mock** | Testing without network | Local JSON files | `MOCK` |
| **Development** | Local development | Google Places API | `DEV` |
| **Staging** | QA testing | Google Places API | `STAGING` |
| **Production** | Production release | Google Places API | `PRD` |
| **Store** | App Store release | Google Places API | `STORE` |

## Quick Build Commands

```bash
# Mock (no network required)
xcodebuild -scheme Mock -configuration Mock build

# Development
xcodebuild -scheme Development -configuration Development build

# Staging
xcodebuild -scheme Staging -configuration Staging build

# Production
xcodebuild -scheme Production -configuration Production build

# Store
xcodebuild -scheme Store -configuration Store build
```

## Xcode Selection

1. Open `AllTrailsLunchApp.xcodeproj`
2. Click scheme dropdown (top left, next to Run/Stop buttons)
3. Select desired scheme
4. Build with `Cmd + B` or Run with `Cmd + R`

## Environment Details

### Mock
```
Data Source: Local JSON files (bundled)
Network: Not required
Timeout: 5 seconds
Use Case: UI development, offline testing, demos
```

### Development
```
Data Source: Google Places API
Network: Required
Timeout: 30 seconds
Use Case: Feature development, debugging
```

### Staging
```
Data Source: Google Places API
Network: Required
Timeout: 30 seconds
Use Case: QA testing, pre-release validation
```

### Production
```
Data Source: Google Places API
Network: Required
Timeout: 30 seconds
Use Case: Production builds, TestFlight
```

### Store
```
Data Source: Google Places API
Network: Required
Timeout: 30 seconds
Use Case: App Store submission
```

## Compilation Flags

Each scheme sets a unique compilation flag:

```swift
#if MOCK
    // Mock configuration
#elseif DEV
    // Development configuration
#elseif STAGING
    // Staging configuration
#elseif STORE
    // Store configuration
#elseif PRD
    // Production configuration
#endif
```

## Configuration Detection

The `AppConfiguration` automatically detects the active environment:

```swift
let config = AppConfiguration.shared
print(config.environment.displayName)
// Output: "Development" or "Mock (Local JSON)" etc.
```

## Common Tasks

### Local Development
1. Select **Development** scheme
2. Ensure valid Google Places API key
3. Build and run

### UI Testing Without Network
1. Select **Mock** scheme
2. Build and run
3. No API key required

### QA Testing
1. Select **Staging** scheme
2. Build and run
3. Test with live API

### Production Build
1. Select **Production** scheme
2. Archive for TestFlight
3. Distribute to testers

### App Store Submission
1. Select **Store** scheme
2. Archive for App Store
3. Submit via App Store Connect

## Verification

Check the Xcode console on app launch:

```
🔧 AppConfiguration: Environment = Development
🔧 AppConfiguration: Use Mock Data = false
🔧 AppConfiguration: Timeout = 30.0s
🔧 AppConfiguration: Places API Base URL = https://maps.googleapis.com/maps/api/place
```

## Troubleshooting

### Wrong Environment Active
- Verify correct scheme selected
- Clean build folder (`Cmd + Shift + K`)
- Rebuild project

### Network Errors
- Check API key is valid
- Verify network connectivity
- Check Google Places API quota

### Mock Data Not Loading
- Verify JSON files in bundle
- Check file syntax
- Ensure files added to target

## Quick Tips

✅ **Use Mock** for UI development without network dependency  
✅ **Use Development** for feature development with live API  
✅ **Use Staging** for QA testing before production  
✅ **Use Production** for TestFlight internal testing  
✅ **Use Store** for final App Store submission  

⚠️ **Never commit API keys** to version control  
⚠️ **Use .xcconfig files** for sensitive configuration  
⚠️ **Rotate API keys** regularly for security  

## Related Documentation

- [BUILD_CONFIGURATIONS.md](BUILD_CONFIGURATIONS.md) - Detailed configuration guide
- [AppConfiguration.swift](AllTrailsLunch/Sources/Core/Config/AppConfiguration.swift) - Configuration implementation

