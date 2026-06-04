#!/bin/bash

# Post-clone script for Xcode Cloud
# Runs Flutter build setup before Xcode tries to build

set -e

echo "Installing Flutter dependencies..."
cd "$CI_PRIMARY_REPOSITORY_PATH"
flutter pub get

echo "Building Flutter for iOS..."
flutter build ios --release --no-codesign

echo "Flutter build complete"
