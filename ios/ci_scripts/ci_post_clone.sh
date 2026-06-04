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
  echo "Error: Flutter not found in PATH or common locations"
  echo "Checked: PATH, ~/.fvm/default/bin, ~/flutter/bin"
  echo "Current PATH=$PATH"
  echo "HOME=$HOME"
  exit 127
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
