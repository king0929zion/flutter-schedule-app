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

# Commit version bump first
git add pubspec.yaml
git commit -m "Bump version to ${new_version} [skip ci]"
git push

# Build
export ANDROID_HOME=/opt/android-sdk
export PATH="/opt/flutter/bin:$PATH"
flutter build apk --release

# Copy APK with version name
cp build/app/outputs/flutter-apk/app-release.apk "app-release-${new_version}.apk"
cp build/app/outputs/flutter-apk/app-release.apk app-release.apk

# Create versioned release
if gh release view "v${new_version}" >/dev/null 2>&1; then
  gh release upload "v${new_version}" "app-release-${new_version}.apk" --clobber
else
  gh release create "v${new_version}" \
    --title "Schedule App v${new_version}" \
    --notes "Auto-build v${new_version}" \
    "app-release-${new_version}.apk"
fi

# Update latest → always has app-release.apk for static URL
if gh release view latest >/dev/null 2>&1; then
  gh release upload latest app-release.apk --clobber
else
  gh release create latest --title "Latest Build" --notes "Latest auto-build" app-release.apk
fi

# Deploy to gh-pages
git checkout gh-pages
cp /tmp/opencode/flutter_schedule_app/build/app/outputs/flutter-apk/app-release.apk app-release.apk
git add app-release.apk
git commit -m "Deploy v${new_version} [skip ci]" || true
git push origin gh-pages
git checkout master

rm -f "app-release-${new_version}.apk" app-release.apk

echo ""
echo "============================================"
echo "✅ Version ${new_version} built and deployed"
echo "============================================"
echo "Static download URLs:"
echo "  GitHub Releases : https://github.com/king0929zion/flutter-schedule-app/releases/latest/download/app-release.apk"
echo "  GitHub Pages    : https://king0929zion.github.io/flutter-schedule-app/app-release.apk"
echo "  Raw (always up) : https://raw.githubusercontent.com/king0929zion/flutter-schedule-app/gh-pages/app-release.apk"
