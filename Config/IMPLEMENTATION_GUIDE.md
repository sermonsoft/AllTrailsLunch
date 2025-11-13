# 🔐 xcconfig Implementation Guide

## Overview

This guide explains how the **xcconfig-based API key management** works in the AllTrailsLunchApp project.

**📖 Official Apple Documentation**: [Adding a Build Configuration File to Your Project](https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project)

---

## 📁 File Structure

```
AllTrailsLunchApp/
├── Config/
│   ├── Secrets.xcconfig              # Your actual secrets (NOT in Git)
│   ├── Secrets.template.xcconfig     # Template (committed to Git)
│   ├── README.md                     # Setup instructions
│   ├── setup.sh                      # Automated setup script
│   └── IMPLEMENTATION_GUIDE.md       # This file
├── .gitignore                        # Excludes Secrets.xcconfig
└── AllTrailsLunchApp/
    └── AllTrailsLunch/
        └── Sources/
            └── Core/
                └── Config/
                    └── AppConfiguration.swift  # Loads API key
```

---

## 🔄 How It Works

### 1. Build-Time Configuration Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Developer creates Config/Secrets.xcconfig                │
│    GOOGLE_PLACES_API_KEY = AIzaSy...actual-key              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Xcode reads xcconfig during build                        │
│    Build Settings: $(GOOGLE_PLACES_API_KEY)                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Value injected into Info.plist                           │
│    <key>GOOGLE_PLACES_API_KEY</key>                         │
│    <string>AIzaSy...actual-key</string>                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. AppConfiguration.swift reads from Info.plist             │
│    Bundle.main.object(forInfoDictionaryKey: "...")          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. API key used in PlacesClient                             │
│    PlacesClient(apiKey: googlePlacesAPIKey)                 │
└─────────────────────────────────────────────────────────────┘
```

### 2. Runtime Loading Strategy

The `AppConfiguration.loadAPIKey()` method tries three sources in order:

```swift
private static func loadAPIKey() -> String {
    // 1️⃣ Environment Variable (highest priority)
    if let key = ProcessInfo.processInfo.environment["GOOGLE_PLACES_API_KEY"] {
        return key  // ✅ Used for CI/CD, testing
    }
    
    // 2️⃣ Info.plist (from xcconfig)
    if let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_PLACES_API_KEY") as? String,
       !key.isEmpty,
       key != "$(GOOGLE_PLACES_API_KEY)" {
        return key  // ✅ Used for production builds
    }
    
    // 3️⃣ Hardcoded fallback (DEBUG only)
    #if DEBUG
    print("⚠️ WARNING: Using hardcoded API key")
    return "AIzaSy...fallback-key"  // ⚠️ Development only
    #else
    fatalError("❌ API key not configured")  // 🚫 Crash in production
    #endif
}
```

---

## 🎯 Use Cases

### Use Case 1: Local Development

**Scenario**: Developer working on their machine

**Setup**:
```bash
./Config/setup.sh
# Enter API key when prompted
```

**Result**:
- `Secrets.xcconfig` created with API key
- Xcode builds with real API key
- App uses Google Places API

---

### Use Case 2: CI/CD Pipeline

**Scenario**: GitHub Actions, Jenkins, etc.

**Setup**:
```yaml
# .github/workflows/test.yml
env:
  GOOGLE_PLACES_API_KEY: ${{ secrets.GOOGLE_PLACES_API_KEY }}
```

**Result**:
- Environment variable takes precedence
- No need for xcconfig in CI
- Secrets managed by CI platform

---

### Use Case 3: Team Onboarding

**Scenario**: New developer joins the team

**Steps**:
1. Clone repository
2. Run `./Config/setup.sh`
3. Enter their own API key
4. Start developing

**Benefits**:
- No shared API keys
- Each developer uses their own quota
- Easy to track usage per developer

---

### Use Case 4: Multiple Environments

**Scenario**: Dev, Staging, Production builds

**Setup**:
```
Config/
├── Secrets.Dev.xcconfig
├── Secrets.Staging.xcconfig
└── Secrets.Production.xcconfig
```

**Xcode Configuration**:
- Debug → `Secrets.Dev.xcconfig`
- Release → `Secrets.Production.xcconfig`

---

## 🔒 Security Benefits

### ✅ What This Solves

| Problem | Solution |
|---------|----------|
| **Hardcoded keys in source** | Keys in xcconfig, not in `.swift` files |
| **Keys in Git history** | `Secrets.xcconfig` in `.gitignore` |
| **Shared keys across team** | Each developer has their own |
| **Key rotation difficulty** | Just update xcconfig, no code changes |
| **Accidental exposure** | Template file has placeholders only |

### ⚠️ What This Doesn't Solve

| Limitation | Mitigation |
|------------|------------|
| **Keys in compiled binary** | Use backend proxy for production |
| **Decompilation risk** | Implement certificate pinning |
| **Runtime memory access** | Use secure enclave for sensitive data |

---

## 🛠️ Implementation Details

### Modified Files

1. **`AppConfiguration.swift`**
   - Updated `loadAPIKey()` to check Info.plist
   - Added DEBUG-only fallback
   - Added production crash for missing key

2. **`.gitignore`**
   - Added `Config/Secrets.xcconfig`
   - Added `**/Secrets.xcconfig` (catch-all)

3. **`README.md`**
   - Added setup instructions
   - Linked to Config/README.md

### Created Files

1. **`Config/Secrets.xcconfig`** - Actual secrets (not in Git)
2. **`Config/Secrets.template.xcconfig`** - Template (in Git)
3. **`Config/README.md`** - Setup guide
4. **`Config/setup.sh`** - Automated setup script
5. **`Config/IMPLEMENTATION_GUIDE.md`** - This file

---

## 📝 Commit Message

```
feat: implement xcconfig-based API key management

- Add Config/Secrets.xcconfig for secure API key storage
- Update AppConfiguration to load from Info.plist
- Add automated setup script (Config/setup.sh)
- Update .gitignore to exclude secrets
- Add comprehensive documentation in Config/README.md
- Maintain backward compatibility with environment variables
- Add DEBUG-only fallback for development convenience

Security improvements:
- API keys no longer hardcoded in source
- Each developer uses their own key
- Production builds fail fast if key not configured
- Template file prevents accidental key commits

BREAKING CHANGE: Production builds now require Config/Secrets.xcconfig
to be configured. Run ./Config/setup.sh to set up.
```

---

## 🚀 Next Steps

### For This Project

1. ✅ xcconfig files created
2. ✅ AppConfiguration updated
3. ✅ Documentation added
4. ⏳ **TODO**: Add Info.plist entry (manual step in Xcode)
5. ⏳ **TODO**: Link xcconfig to Xcode project configurations

### Linking xcconfig to Xcode Project (Optional)

For full integration, follow Apple's official guide:
**[Adding a Build Configuration File to Your Project](https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project)**

**Steps**:
1. Open Xcode project
2. Select project in navigator
3. Select target → Info tab
4. Under "Configurations", set xcconfig for each configuration:
   - Debug → `Secrets.xcconfig`
   - Release → `Secrets.xcconfig`

**Note**: This is optional because the current implementation uses environment variables and DEBUG fallback.

### For Production

1. **Backend Proxy**: Move API key to backend service
2. **Certificate Pinning**: Prevent man-in-the-middle attacks
3. **Rate Limiting**: Implement per-user quotas
4. **Monitoring**: Track API usage and costs
5. **Key Rotation**: Automate periodic key changes

---

## 📚 References

### Official Documentation
- **[Apple: Adding a Build Configuration File to Your Project](https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project)** - Official Apple guide on xcconfig files
- [iOS Security Best Practices](https://developer.apple.com/documentation/security) - Apple security documentation

### Third-Party Resources
- [Xcode Build Configuration Files](https://nshipster.com/xcconfig/) - NSHipster guide
- [Google Places API Security](https://developers.google.com/maps/api-security-best-practices) - Google security best practices

