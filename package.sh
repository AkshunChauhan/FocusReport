#!/bin/bash

# FocusReport Packaging Script
# This script automates the creation of a DMG for distribution.

APP_NAME="FocusReport"
BUILD_DIR="build/Release"
DIST_DIR="dist"
DMG_NAME="FocusReport.dmg"

# Ensure we're in the right directory
cd "$(dirname "$0")"

echo "🚀 Starting build..."
mkdir -p build

# Clean and build release
xcodebuild -scheme "$APP_NAME" -configuration Release -derivedDataPath build CONFIGURATION_BUILD_DIR="$BUILD_DIR" clean build

if [ $? -eq 0 ]; then
    echo "✅ Build Succeeded!"
    
    echo "📂 Preparing distribution folder..."
    rm -rf "$DIST_DIR"
    mkdir -p "$DIST_DIR"
    cp -R "$BUILD_DIR/$APP_NAME.app" "$DIST_DIR/"
    ln -s /Applications "$DIST_DIR/Applications"
    
    echo "💿 Creating DMG..."
    rm -f "$DMG_NAME"
    hdiutil create -volname "$APP_NAME" -srcfolder "$DIST_DIR" -ov -format UDZO "$DMG_NAME"
    
    echo "✨ Packaging Complete! Created: $DMG_NAME"
    
    # Optional: Clean up
    # rm -rf "$DIST_DIR"
else
    echo "❌ Build Failed."
    exit 1
fi
