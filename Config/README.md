# 🔐 Configuration Setup Guide

This directory contains configuration files for managing API keys and secrets securely.

## 📁 Files

- **`Secrets.template.xcconfig`** - Template file (committed to Git)
- **`Secrets.xcconfig`** - Your actual secrets (NOT committed to Git)

## 🚀 Quick Setup

### 1. Copy the Template

```bash
cd Config
cp Secrets.template.xcconfig Secrets.xcconfig
```

### 2. Add Your API Key

Edit `Secrets.xcconfig` and replace `YOUR_API_KEY_HERE` with your actual Google Places API key:

```
GOOGLE_PLACES_API_KEY = AIzaSy...your-actual-key-here
```

### 3. Get Your API Key

If you don't have a Google Places API key:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the **Places API**
4. Go to **Credentials** → **Create Credentials** → **API Key**
5. Copy the API key and paste it into `Secrets.xcconfig`

### 4. Configure Xcode Project

**Option A: Using xcconfig in Xcode (Recommended)**

Follow Apple's official guide: **[Adding a Build Configuration File to Your Project](https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project)**

1. Open `AllTrailsLunchApp.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the **AllTrailsLunchApp** target
4. Go to the **Info** tab
5. Under **Configurations**, set:
   - **Debug** → `Secrets`
   - **Release** → `Secrets`

**Option B: Add to Info.plist**

Add this key-value pair to your `Info.plist`:

```xml
<key>GOOGLE_PLACES_API_KEY</key>
<string>$(GOOGLE_PLACES_API_KEY)</string>
```

The `$(GOOGLE_PLACES_API_KEY)` will be replaced with the value from `Secrets.xcconfig` at build time.

## 🔒 Security

### ✅ What's Safe

- ✅ `Secrets.template.xcconfig` - Template with placeholders (committed to Git)
- ✅ `README.md` - This documentation (committed to Git)

### ❌ What's NOT Safe

- ❌ `Secrets.xcconfig` - Contains real API keys (added to `.gitignore`)
- ❌ Hardcoded API keys in source code
- ❌ API keys in commit history

### 🛡️ Best Practices

1. **Never commit `Secrets.xcconfig`** - It's in `.gitignore`
2. **Rotate keys regularly** - Change API keys periodically
3. **Use different keys per environment** - Dev, Staging, Production
4. **Restrict API key usage** - Set restrictions in Google Cloud Console
5. **Monitor usage** - Check Google Cloud Console for unusual activity

## 🔄 How It Works

### Build-Time Injection

```
Secrets.xcconfig
    ↓
GOOGLE_PLACES_API_KEY = AIzaSy...
    ↓
Info.plist (at build time)
    ↓
$(GOOGLE_PLACES_API_KEY) → AIzaSy...
    ↓
AppConfiguration.swift
    ↓
Bundle.main.object(forInfoDictionaryKey: "GOOGLE_PLACES_API_KEY")
```

### Fallback Strategy

The app tries to load the API key in this order:

1. **Environment Variable** - `GOOGLE_PLACES_API_KEY` (for CI/CD)
2. **Info.plist** - Loaded from xcconfig (for production)
3. **Hardcoded** - Only in DEBUG builds (for development)

## 🧪 Testing

### Verify Configuration

Run the app and check the console output:

```
🔧 AppConfiguration: Environment = Development
🔧 AppConfiguration: Use Mock Data = false
🔧 AppConfiguration: Timeout = 10.0s
🔧 AppConfiguration: Places API Base URL = https://maps.googleapis.com
```

If you see the warning:
```
⚠️ WARNING: Using hardcoded API key. Configure Secrets.xcconfig for production.
```

Then the xcconfig is not properly configured.

### Override for Testing

You can override the API key using environment variables in Xcode:

1. **Product** → **Scheme** → **Edit Scheme...**
2. **Run** → **Arguments** → **Environment Variables**
3. Add: `GOOGLE_PLACES_API_KEY = your-test-key`

## 🆘 Troubleshooting

### "API key not configured" error

**Problem**: App crashes with `fatalError` in Release builds

**Solution**: 
1. Make sure `Secrets.xcconfig` exists
2. Verify the API key is set correctly
3. Check that xcconfig is linked to the target
4. Clean build folder (Cmd+Shift+K) and rebuild

### xcconfig not being read

**Problem**: App still uses hardcoded key

**Solution**:
1. Check that `Secrets.xcconfig` is in the `Config/` directory
2. Verify Info.plist has `$(GOOGLE_PLACES_API_KEY)` placeholder
3. Make sure the xcconfig is set in project configurations
4. Clean and rebuild

### API key exposed in Git

**Problem**: Accidentally committed `Secrets.xcconfig`

**Solution**:
```bash
# Remove from Git but keep locally
git rm --cached Config/Secrets.xcconfig

# Verify .gitignore has the entry
echo "Config/Secrets.xcconfig" >> .gitignore

# Commit the removal
git commit -m "chore: remove exposed API key from Git"

# Rotate the API key in Google Cloud Console
```

## 📚 Additional Resources

- **[Apple: Adding a Build Configuration File to Your Project](https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project)** - Official Apple documentation
- [Google Places API Documentation](https://developers.google.com/maps/documentation/places/web-service)
- [Xcode Build Configuration Files](https://nshipster.com/xcconfig/)
- [iOS Security Best Practices](https://developer.apple.com/documentation/security)

