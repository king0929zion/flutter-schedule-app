#!/bin/bash
set -e

cd "$(dirname "$0")/.."

# Bump version
current=$(grep '^version: ' pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
build=$(grep '^version: ' pubspec.yaml | sed 's/.*+//')
new_build=$((build + 1))
new_version="${current}+${new_build}"
sed -i "s/^version: .*/version: $new_version/" pubspec.yaml

echo "Building version: $new_version"

# Build
export ANDROID_HOME=/opt/android-sdk
export PATH="/opt/flutter/bin:$PATH"
flutter build apk --release

# Copy APK
cp build/app/outputs/flutter-apk/app-release.apk "app-release-${new_version}.apk"

# Create GitHub release
gh release create "v${new_version}" \
  --title "Schedule App v${new_version}" \
  --notes "Auto-build v${new_version}" \
  "app-release-${new_version}.apk" || \
gh release upload "v${new_version}" "app-release-${new_version}.apk" --clobber

# Also update the latest tag
gh release upload latest "app-release-${new_version}.apk" --clobber 2>/dev/null || \
gh release create latest \
  --title "Latest Build" \
  --notes "Latest auto-build" \
  "app-release-${new_version}.apk" || true

rm -f "app-release-${new_version}.apk"

# Push version change
git add pubspec.yaml
git commit -m "Bump version to $new_version [skip ci]"
git push

echo ""
echo "Download URL: https://github.com/king0929zion/flutter-schedule-app/releases/latest/download/app-release-${new_version}.apk"
echo "Latest always: https://github.com/king0929zion/flutter-schedule-app/releases/latest/download/app-release.apk"
