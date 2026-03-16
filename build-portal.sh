#!/usr/bin/env bash
set -euo pipefail

# Smart Retail Portal Builder
# Usage: ./build-portal.sh [public|admin|merchant|staff|shop|customer] [platform...]
# Platforms: web apk appbundle ios macos linux windows all

PORTAL="${1:-}"
if [[ -z "$PORTAL" ]]; then
    echo "Usage: ./build-portal.sh [public|admin|merchant|staff|shop|customer] [platform ...]"
    exit 1
fi

if [[ "$PORTAL" == "customer" ]]; then
    PORTAL="public"
fi

case "$PORTAL" in
    public|admin|merchant|staff|shop) ;;
    *)
        echo "Error: invalid portal '$PORTAL'"
        exit 1
        ;;
esac

shift || true
if [[ "$#" -eq 0 ]]; then
    PLATFORMS=(web)
else
    if [[ "$1" == "all" ]]; then
        PLATFORMS=(web apk appbundle ios macos linux windows)
    else
        PLATFORMS=("$@")
    fi
fi

ENV_FILE=".env.${PORTAL}"
if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: $ENV_FILE not found"
    exit 1
fi

echo "========================================"
echo "Smart Retail Portal Builder"
echo "Portal: $PORTAL"
echo "Platforms: ${PLATFORMS[*]}"
echo "========================================"

cp "$ENV_FILE" .env
TARGET_FILE="lib/main_${PORTAL}.dart"
if [[ ! -f "$TARGET_FILE" ]]; then
    echo "Error: $TARGET_FILE not found"
    exit 1
fi
flutter pub get

mkdir -p "build/artifacts/$PORTAL"

for platform in "${PLATFORMS[@]}"; do
    out_dir="build/artifacts/$PORTAL/$platform"
    rm -rf "$out_dir"
    mkdir -p "$out_dir"

    echo "---- Building $PORTAL / $platform ----"
    case "$platform" in
        web)
            flutter build web --release --target="$TARGET_FILE"
            cp -R build/web "$out_dir/web"
            ;;
        apk)
            flutter build apk --release --target="$TARGET_FILE"
            cp build/app/outputs/flutter-apk/app-release.apk "$out_dir/smart-retail-$PORTAL-release.apk"
            ;;
        appbundle)
            flutter build appbundle --release --target="$TARGET_FILE"
            cp build/app/outputs/bundle/release/app-release.aab "$out_dir/smart-retail-$PORTAL-release.aab"
            ;;
        ios)
            flutter build ios --release --target="$TARGET_FILE"
            cp -R build/ios "$out_dir/ios"
            ;;
        macos)
            flutter build macos --release --target="$TARGET_FILE"
            cp -R build/macos/Build/Products/Release "$out_dir/macos-release"
            ;;
        linux)
            flutter build linux --release --target="$TARGET_FILE"
            cp -R build/linux/x64/release/bundle "$out_dir/linux-bundle"
            ;;
        windows)
            flutter build windows --release --target="$TARGET_FILE"
            cp -R build/windows/x64/runner/Release "$out_dir/windows-release"
            ;;
        *)
            echo "Error: unsupported platform '$platform'"
            exit 1
            ;;
    esac
done

echo "Build matrix complete: build/artifacts/$PORTAL"
