# Portal Deployment Guide

This project supports two separate portal deployments:
1. **Admin Portal** - For administrative access only
2. **Customer Portal** - For merchants, shops, and staff

## Portal Configuration

The portal type is controlled by the `DEPLOY_PORTAL` environment variable in the `.env` file.

### Environment Files

- **`.env.admin`** - Admin portal configuration (`DEPLOY_PORTAL=admin`)
- **`.env.customer`** - Customer portal configuration (`DEPLOY_PORTAL=customer`)
- **`.env`** - Default configuration (currently set to admin)

## Building for Different Portals

### Admin Portal Build

```bash
# Copy admin environment
cp .env.admin .env

# Run the app
flutter run

# Or build for production
flutter build web
flutter build apk
flutter build ios
```

### Customer Portal Build

```bash
# Copy customer environment
cp .env.customer .env

# Run the app
flutter run

# Or build for production
flutter build web
flutter build apk
flutter build ios
```

## Portal Differences

### Admin Portal
- **Initial Screen**: Simple admin login page
- **Features**: Only admin login button
- **Design**: Minimal and professional
- **Routes**: `/admin-intro` → `/admin/login`

### Customer Portal
- **Initial Screen**: Full landing page with scrollable sections
- **Features**: 
  - Hero section with branding
  - Features showcase
  - Three login buttons (Merchant, Shop, Staff)
  - About section
  - Footer
- **Design**: Modern, colorful, and engaging
- **Routes**: `/customer-intro` → `/merchant/login`, `/shop/login`, `/staff/login`

## Portal Features

The portal configuration automatically:
- Shows the correct intro/landing page on app start
- Sets the app title (`Smart Retail Admin` vs `Smart Retail`)
- Configures available routes and features
- Can be extended to show/hide features based on portal type

## Development

During development, you can quickly switch portals by:

1. Editing `.env` file directly:
   ```properties
   DEPLOY_PORTAL=admin   # For admin portal
   DEPLOY_PORTAL=customer  # For customer portal
   ```

2. Hot restart the app (not just hot reload)

## Production Deployment

For production, build separate artifacts:

### Web Deployment
```bash
# Admin Portal
cp .env.admin .env
flutter build web --release
mv build/web build/admin-portal

# Customer Portal
cp .env.customer .env
flutter build web --release
mv build/web build/customer-portal
```

### Mobile Deployment
```bash
# Admin Portal APK
cp .env.admin .env
flutter build apk --release
mv build/app/outputs/flutter-apk/app-release.apk smart-retail-admin.apk

# Customer Portal APK
cp .env.customer .env
flutter build apk --release
mv build/app/outputs/flutter-apk/app-release.apk smart-retail-customer.apk
```

## CI/CD Integration

Example GitHub Actions workflow:

```yaml
jobs:
  build-admin:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - run: cp .env.admin .env
      - run: flutter build web --release
      
  build-customer:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - run: cp .env.customer .env
      - run: flutter build web --release
```

## Notes

- The `.env` file is git-ignored for security
- Always ensure the correct `.env` file is used before building
- Portal configuration is read once at app initialization
- Changing portal requires app restart, not just hot reload
