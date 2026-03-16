# Portal Deployment Guide

This project now supports 4 deployment portals:

1. `public` (landing website with support/contact)
2. `admin`
3. `merchant`
4. `staff`

Optional internal target:
- `shop`

## Portal Selection

Portal boot route is selected by:

1. `--dart-define=APP_PORTAL=<portal>` (highest priority)
2. `.env` value `DEPLOY_PORTAL=<portal>`

`customer` is treated as alias for `public`.

## Environment Files

Available env presets:

- `.env.public`
- `.env.admin`
- `.env.merchant`
- `.env.staff`
- `.env.shop`

Each build script copies `.env.<portal>` into `.env` before building.

## Build Scripts

### Single portal, selected platforms

Windows:

```bat
build-portal.bat public web
build-portal.bat admin web windows
build-portal.bat merchant apk appbundle
build-portal.bat staff all
```

Linux/macOS:

```bash
./build-portal.sh public web
./build-portal.sh admin web linux
./build-portal.sh merchant apk appbundle
./build-portal.sh staff all
```

Supported platforms:
- `web`
- `apk`
- `appbundle`
- `windows`
- `linux`
- `macos`
- `ios`
- `all`

## Build all portals

Windows:

```bat
build-all-portals.bat web
build-all-portals.bat apk appbundle
build-all-portals.bat all
```

Linux/macOS:

```bash
./build-all-portals.sh web
./build-all-portals.sh apk appbundle
./build-all-portals.sh all
```

## Per-portal wrappers

Windows:
- `build-public-all.bat`
- `build-admin-all.bat`
- `build-merchant-all.bat`
- `build-staff-all.bat`

Linux/macOS:
- `build-public-all.sh`
- `build-admin-all.sh`
- `build-merchant-all.sh`
- `build-staff-all.sh`

## Output Structure

Artifacts are separated by portal and platform:

```text
build/artifacts/<portal>/<platform>/...
```

Examples:
- `build/artifacts/public/web/web`
- `build/artifacts/admin/windows/windows-release`
- `build/artifacts/merchant/apk/smart-retail-merchant-release.apk`
- `build/artifacts/staff/appbundle/smart-retail-staff-release.aab`

## Host Platform Notes

- Windows host skips `ios`, `macos`, `linux` builds.
- Linux host cannot build `ios`/`macos`.
- macOS host can build all targets (with proper SDK/tooling installed).

## Troubleshooting Checklist

1. Run `flutter pub get`.
2. Verify `API_BASE_URL` in `.env.<portal>` or pass `--dart-define=API_BASE_URL=...`.
3. Confirm mobile signing config for release builds.
4. Ensure platform tooling is installed (`xcode`, Android SDK, Windows build tools, etc.).
5. Use `flutter analyze` and test commands before final release packaging.
