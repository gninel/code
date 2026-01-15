#!/bin/bash
set -e

echo "=========================================="
echo "Starting Android Automated Test Suite"
echo "=========================================="

# 1. Clean & Setup
echo "Step 1: Cleaning project and getting dependencies..."
flutter clean
flutter pub get

# 2. Static Analysis
echo "Step 2: Running Static Analysis..."
flutter analyze || true

# 3. Host-side Tests
echo "Step 3: Running Unit and Integration Tests (Host)..."
# Running all tests in test/ directory
flutter test

# 4. Android Integration Tests
echo "Step 4: Checking for connected Android devices..."
# Check for android device ID (simple check)
if flutter devices | grep -i "android"; then
    echo "Android device found. Running on-device integration tests..."
    # Run integration test on the first available android device
    # Note: If multiple devices, might need to specify -d <device_id>
    flutter test integration_test/app_test.dart -d android
else
    echo "WARNING: No Android device/emulator found. Skipping on-device tests."
    echo "Tip: Connect a device or start an emulator to run UI automation tests."
fi

# 5. Build Release APK
echo "Step 5: Building Release APK..."
flutter build apk --release

echo "=========================================="
echo "Test Plan Completed Successfully!"
echo "Release APK: build/app/outputs/flutter-apk/app-release.apk"
echo "=========================================="
