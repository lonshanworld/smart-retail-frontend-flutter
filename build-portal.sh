#!/bin/bash

# Smart Retail Portal Builder
# Usage: ./build-portal.sh [admin|customer] [web|apk|ios]

PORTAL_TYPE=$1
BUILD_TYPE=$2

if [ -z "$PORTAL_TYPE" ] || [ -z "$BUILD_TYPE" ]; then
    echo "Usage: ./build-portal.sh [admin|customer] [web|apk|ios]"
    echo ""
    echo "Examples:"
    echo "  ./build-portal.sh admin web      # Build admin portal for web"
    echo "  ./build-portal.sh customer apk   # Build customer portal for Android"
    exit 1
fi

# Validate portal type
if [ "$PORTAL_TYPE" != "admin" ] && [ "$PORTAL_TYPE" != "customer" ]; then
    echo "Error: Portal type must be 'admin' or 'customer'"
    exit 1
fi

# Validate build type
if [ "$BUILD_TYPE" != "web" ] && [ "$BUILD_TYPE" != "apk" ] && [ "$BUILD_TYPE" != "ios" ]; then
    echo "Error: Build type must be 'web', 'apk', or 'ios'"
    exit 1
fi

echo "================================================"
echo "  Smart Retail Portal Builder"
echo "================================================"
echo "Portal: $PORTAL_TYPE"
echo "Build Type: $BUILD_TYPE"
echo ""

# Copy the appropriate .env file
echo "📋 Copying .env.$PORTAL_TYPE to .env..."
cp .env.$PORTAL_TYPE .env

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to copy .env.$PORTAL_TYPE"
    exit 1
fi

echo "✅ Environment configured for $PORTAL_TYPE portal"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build based on type
echo ""
echo "🔨 Building $PORTAL_TYPE portal for $BUILD_TYPE..."
echo ""

case $BUILD_TYPE in
    web)
        flutter build web --release
        BUILD_OUTPUT="build/web"
        ;;
    apk)
        flutter build apk --release
        BUILD_OUTPUT="build/app/outputs/flutter-apk/app-release.apk"
        ;;
    ios)
        flutter build ios --release
        BUILD_OUTPUT="build/ios"
        ;;
esac

if [ $? -eq 0 ]; then
    echo ""
    echo "================================================"
    echo "✅ BUILD SUCCESSFUL!"
    echo "================================================"
    echo "Portal: $PORTAL_TYPE"
    echo "Build Type: $BUILD_TYPE"
    echo "Output: $BUILD_OUTPUT"
    echo ""
    
    # Rename output for clarity
    if [ "$BUILD_TYPE" == "apk" ]; then
        mv $BUILD_OUTPUT "build/smart-retail-$PORTAL_TYPE.apk"
        echo "📱 APK renamed to: build/smart-retail-$PORTAL_TYPE.apk"
    elif [ "$BUILD_TYPE" == "web" ]; then
        if [ -d "build/$PORTAL_TYPE-portal" ]; then
            rm -rf "build/$PORTAL_TYPE-portal"
        fi
        mv build/web "build/$PORTAL_TYPE-portal"
        echo "🌐 Web build moved to: build/$PORTAL_TYPE-portal"
    fi
    
    echo ""
else
    echo ""
    echo "❌ BUILD FAILED!"
    exit 1
fi
