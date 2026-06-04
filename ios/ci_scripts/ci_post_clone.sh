#!/bin/bash

# Post-clone script for Xcode Cloud
# Runs Flutter build setup before Xcode tries to build

set -e

# Source shell profile to get environment variables (including PATH with flutter)
if [ -f "$HOME/.zshrc" ]; then
  source "$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
  source "$HOME/.bashrc"
fi

cd "$CI_PRIMARY_REPOSITORY_PATH"

# Try to find flutter in various locations
FLUTTER_CMD=""

if command -v flutter &> /dev/null; then
  FLUTTER_CMD="flutter"
elif [ -d "$HOME/.fvm/default/bin" ]; then
  # Check for FVM (Flutter Version Management)
  FLUTTER_CMD="$HOME/.fvm/default/bin/flutter"
elif [ -d "$HOME/flutter/bin" ]; then
  # Check for flutter in home directory
  FLUTTER_CMD="$HOME/flutter/bin/flutter"
fi

if [ -z "$FLUTTER_CMD" ]; then
  echo "Flutter not found. Downloading from official source..."

  # Download and extract Flutter SDK
  FLUTTER_INSTALL_DIR="$HOME/flutter"
  mkdir -p "$FLUTTER_INSTALL_DIR"

  # Detect macOS architecture
  ARCH=$(uname -m)
  if [ "$ARCH" = "arm64" ]; then
    FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64.zip"
  else
    FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_x64.zip"
  fi

  echo "Downloading Flutter for $ARCH from $FLUTTER_URL..."
  curl -L -o /tmp/flutter.zip "$FLUTTER_URL" || {
    echo "Failed to download Flutter"
    exit 127
  }

  echo "Extracting Flutter..."
  unzip -q -o /tmp/flutter.zip -d "$HOME" || {
    echo "Failed to extract Flutter"
    exit 127
  }

  rm /tmp/flutter.zip
  FLUTTER_CMD="$HOME/flutter/bin/flutter"

  if [ ! -f "$FLUTTER_CMD" ]; then
    echo "Error: Flutter binary not found after extraction"
    exit 127
  fi
fi

# Use the found flutter command
FLUTTER="$FLUTTER_CMD"

echo "Flutter version:"
$FLUTTER --version

echo "Installing Flutter dependencies..."
$FLUTTER pub get

echo "Building Flutter for iOS..."
$FLUTTER build ios --release --no-codesign

echo "Flutter build complete"
