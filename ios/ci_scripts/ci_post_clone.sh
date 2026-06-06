#!/bin/sh

# Fail this script if any subcommand fails.
set -e

# The default execution directory of this script is the ci_scripts directory.
cd $CI_PRIMARY_REPOSITORY_PATH

# Install Flutter using git.
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Install Flutter artifacts for iOS.
flutter precache --ios

# Install Flutter dependencies.
flutter pub get

# Install CocoaPods using Homebrew.
HOMEBREW_NO_AUTO_UPDATE=1
brew install cocoapods

# --- Fix pod install network: AppAuth is fetched via `git clone`, which Xcode
# Cloud downgrades to http:// through a dead proxy (172.16.33.195:8088).
# Everything else egresses fine over direct HTTPS, so just bypass the proxy. ---
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
git config --global --unset-all http.proxy  2>/dev/null || true
git config --global --unset-all https.proxy 2>/dev/null || true
git config --global --remove-section url."http://github.com/" 2>/dev/null || true
git config --global url."https://github.com/".insteadOf "git://github.com/"

echo "=== effective git config ==="; git config --global --list || true
echo "=== proxy env ==="; env | grep -i proxy || true

# Install CocoaPods dependencies.
cd ios && pod install

exit 0
