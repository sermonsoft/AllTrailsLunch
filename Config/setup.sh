#!/bin/bash

# Setup script for AllTrailsLunchApp configuration
# This script helps set up the Secrets.xcconfig file

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SECRETS_FILE="$SCRIPT_DIR/Secrets.xcconfig"
TEMPLATE_FILE="$SCRIPT_DIR/Secrets.template.xcconfig"

echo "🔧 AllTrailsLunchApp Configuration Setup"
echo "========================================"
echo ""

# Check if Secrets.xcconfig already exists
if [ -f "$SECRETS_FILE" ]; then
    echo "⚠️  Secrets.xcconfig already exists!"
    echo ""
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Setup cancelled."
        exit 0
    fi
fi

# Copy template
echo "📋 Copying template..."
cp "$TEMPLATE_FILE" "$SECRETS_FILE"
echo "✅ Created Secrets.xcconfig"
echo ""

# Prompt for API key
echo "🔑 Google Places API Key Setup"
echo "------------------------------"
echo ""
echo "You need a Google Places API key to run this app."
echo "Get one from: https://console.cloud.google.com/apis/credentials"
echo ""
read -p "Enter your Google Places API key (or press Enter to skip): " API_KEY

if [ -n "$API_KEY" ]; then
    # Replace placeholder with actual key
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/YOUR_API_KEY_HERE/$API_KEY/" "$SECRETS_FILE"
    else
        # Linux
        sed -i "s/YOUR_API_KEY_HERE/$API_KEY/" "$SECRETS_FILE"
    fi
    echo "✅ API key configured!"
else
    echo "⚠️  Skipped API key configuration."
    echo "   You can manually edit Config/Secrets.xcconfig later."
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo "   1. If you skipped the API key, edit Config/Secrets.xcconfig"
echo "   2. Open AllTrailsLunchApp.xcodeproj in Xcode"
echo "   3. Build and run the app"
echo ""
echo "📚 For more information, see Config/README.md"

