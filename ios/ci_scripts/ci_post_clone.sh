#!/bin/bash
set -e

cd "$CI_PRIMARY_REPOSITORY_PATH"

# Only goal: generate Flutter's Generated.xcconfig
# The Xcode build phases will handle the rest
flutter pub get
