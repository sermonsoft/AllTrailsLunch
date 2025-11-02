# Build Configurations Guide

This document explains how to use different build configurations for the AllTrails Lunch app across different environments.

## Overview

The app supports **5 build configurations** that automatically configure the appropriate environment settings:

| Configuration | Compilation Flag | Use Case | Google Places API |
|--------------|------------------|----------|-------------------|
| **Mock** | `MOCK` | Testing without network | Mock data (local JSON) |
| **Development** | `DEV` | Local development | Live Google Places API |
| **Staging** | `STAGING` | QA testing | Live Google Places API |
| **Production** | `PRD` | Production release | Live Google Places API |
| **Store** | `STORE` | App Store release | Live Google Places API |

## How It Works

The app uses **Swift compilation flags** to determine the active environment:

1. **AppConfiguration** detects the active compilation flag
2. Based on the flag, it configures:
   - API base URLs
   - Timeout intervals
   - Mock data usage
   - Environment-specific settings

## Switching Between Configurations

### In Xcode

1. **Select the scheme**: Click on the scheme selector (next to the Run/Stop buttons)
2. **Choose the desired scheme**:
   - **Mock** - For testing without network
   - **Development** - For local development
   - **Staging** - For QA testing
   - **Production** - For production builds
   - **Store** - For App Store submission
3. **Build and Run**: Press `Cmd + R`

### From Command Line

```bash
# Build with Mock configuration
xcodebuild -project AllTrailsLunchApp.xcodeproj \
  -scheme Mock \
  -configuration Mock \
  build

# Build with Development configuration
xcodebuild -project AllTrailsLunchApp.xcodeproj \
  -scheme Development \
  -configuration Development \
  build

# Build with Staging configuration
xcodebuild -project AllTrailsLunchApp.xcodeproj \
  -scheme Staging \
  -configuration Staging \
  build

# Build with Production configuration
xcodebuild -project AllTrailsLunchApp.xcodeproj \
  -scheme Production \
  -configuration Production \
  build

# Build with Store configuration
xcodebuild -project AllTrailsLunchApp.xcodeproj \
  -scheme Store \
  -configuration Store \
  build
```

## Configuration Details

### Mock Configuration

**Compilation Flag**: `MOCK`

**Use Case**: 
- Testing without network connectivity
- UI development
- Offline development
- Demo purposes

**Features**:
- Uses local mock data (JSON files)
- No network requests
- Fast and predictable
- Timeout: 5 seconds

**Advantages**:
- No API key required
- Works offline
- Instant data loading
- Predictable test data

### Development Configuration

**Compilation Flag**: `DEV`

**Use Case**:
- Local development
- Feature development
- Integration testing
- Debugging

**Features**:
- Live Google Places API
- Full debug symbols
- Testability enabled
- Timeout: 30 seconds

**Requirements**:
- Valid Google Places API key
- Network connectivity

### Staging Configuration

**Compilation Flag**: `STAGING`

**Use Case**:
- QA testing
- Pre-release testing
- Staging environment validation
- Beta testing

**Features**:
- Live Google Places API
- Debug symbols included
- Timeout: 30 seconds

**Requirements**:
- Valid Google Places API key
- Network connectivity

### Production Configuration

**Compilation Flag**: `PRD`

**Use Case**:
- Production release builds
- Internal distribution
- TestFlight builds

**Features**:
- Live Google Places API
- Release optimizations
- Timeout: 30 seconds

**Requirements**:
- Valid Google Places API key
- Network connectivity

### Store Configuration

**Compilation Flag**: `STORE`

**Use Case**:
- App Store submission
- Final release builds
- Production validation

**Features**:
- Live Google Places API
- Full release optimizations
- App Store validation enabled
- Timeout: 30 seconds

**Requirements**:
- Valid Google Places API key
- Network connectivity
- Proper code signing

## Environment Detection

The `AppConfiguration` detects the active environment in the following order:

1. **Environment Variables** (highest priority)
   - `ENV` or `CONFIG` environment variable
   - Useful for UI tests and automation

2. **Launch Arguments**
   - Command-line arguments passed to the app
   - Useful for testing specific configurations

3. **Compilation Flags** (default)
   - Set by the Xcode build configuration
   - Most common method

### Example: Override via Environment Variable

```swift
// In UI tests
let app = XCUIApplication()
app.launchEnvironment = ["ENV": "MOCK"]
app.launch()
```

### Example: Override via Launch Arguments

```swift
// In UI tests
let app = XCUIApplication()
app.launchArguments = ["MOCK"]
app.launch()
```

## Verifying Active Configuration

When the app launches, check the Xcode console for configuration logs:

```
🔧 AppConfiguration: Environment = Development
🔧 AppConfiguration: Use Mock Data = false
🔧 AppConfiguration: Timeout = 30.0s
🔧 AppConfiguration: Places API Base URL = https://maps.googleapis.com/maps/api/place
```

or for Mock:

```
🔧 AppConfiguration: Environment = Mock (Local JSON)
🔧 AppConfiguration: Use Mock Data = true
🔧 AppConfiguration: Timeout = 5.0s
```

## API Configuration

### Google Places API Key

The API key is loaded in the following order:

1. **Environment Variable**: `GOOGLE_PLACES_API_KEY`
2. **Embedded Key**: Fallback key in `AppConfiguration.swift`

**For Production**: Store the API key in an `.xcconfig` file (not committed to git):

```
// Config/Production.xcconfig
GOOGLE_PLACES_API_KEY = your_production_api_key_here
```

### Base URLs

All configurations use the same Google Places API base URL:

```
https://maps.googleapis.com/maps/api/place
```

The Mock configuration doesn't use network requests.

## Compilation Flags

Each scheme sets a unique compilation flag in the build settings:

```swift
#if MOCK
    // Mock configuration code
#elseif DEV
    // Development configuration code
#elseif STAGING
    // Staging configuration code
#elseif STORE
    // Store configuration code
#elseif PRD
    // Production configuration code
#endif
```

### Build Settings

| Scheme | SWIFT_ACTIVE_COMPILATION_CONDITIONS |
|--------|-------------------------------------|
| Mock | `MOCK DEBUG` |
| Development | `DEV DEBUG` |
| Staging | `STAGING DEBUG` |
| Production | `PRD` |
| Store | `STORE` |

## Troubleshooting

### Mock Configuration Issues

**Problem**: App crashes or shows no data

**Solutions**:
- Verify mock JSON files exist in the bundle
- Check JSON file syntax
- Ensure files are added to the target

### API Configuration Issues

**Problem**: Network errors or "Invalid API key"

**Solutions**:
- Verify Google Places API key is valid
- Check API key has Places API enabled
- Ensure network connectivity
- Check API quota limits

### Build Configuration Issues

**Problem**: Wrong environment is active

**Solutions**:
- Verify correct scheme is selected
- Check build configuration in scheme settings
- Clean build folder (`Cmd + Shift + K`)
- Rebuild project (`Cmd + B`)

## Best Practices

1. **Use Mock for UI Development**: Develop UI without network dependency
2. **Use Development for Feature Work**: Test with live API during development
3. **Use Staging for QA**: Test in staging environment before production
4. **Use Production for TestFlight**: Internal testing with production settings
5. **Use Store for App Store**: Final release builds only

## Security Notes

⚠️ **Never commit API keys to version control**

- Use `.xcconfig` files for sensitive data
- Add `.xcconfig` to `.gitignore`
- Use environment variables for CI/CD
- Rotate API keys regularly
- Use different keys for each environment

## Related Files

- `AllTrailsLunch/Sources/Core/Config/AppConfiguration.swift` - Main configuration
- `AllTrailsLunchApp.xcodeproj/project.pbxproj` - Build settings
- `AllTrailsLunchApp.xcodeproj/xcshareddata/xcschemes/` - Scheme definitions

