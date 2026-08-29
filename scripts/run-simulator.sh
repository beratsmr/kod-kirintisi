#!/bin/bash
#
# Builds Codestion and launches it on a simulator.
#
# The manual checks M7 needs — notification permission, Spotlight results,
# Siri shortcuts — cannot be verified by a build, only by running the thing.
# This is the shortest path from a clean checkout to a running app.
#
#   ./scripts/run-simulator.sh                 # iPhone 17
#   ./scripts/run-simulator.sh "iPhone 17 Pro" # any booted-or-bootable device
#
# See `xcrun simctl list devices available` for the names on this machine.

set -euo pipefail

DEVICE="${1:-iPhone 17}"
SCHEME="KodKirintisi"
BUNDLE_ID="com.beratsumer.kodkirintisi"

cd "$(dirname "$0")/.."

# The .xcodeproj is generated and gitignored, so it may not exist yet — and
# regenerating is cheap enough not to bother checking whether it is stale.
echo "==> Generating project"
xcodegen generate

echo "==> Building for $DEVICE"
xcodebuild build \
	-project KodKirintisi.xcodeproj \
	-scheme "$SCHEME" \
	-destination "platform=iOS Simulator,name=$DEVICE" \
	-quiet

# Asking xcodebuild where it put the app beats guessing at the DerivedData
# path, which is hashed and moves. The product name has a space and Turkish
# letters in it, so every expansion below stays quoted.
SETTINGS=$(xcodebuild -project KodKirintisi.xcodeproj \
	-scheme "$SCHEME" \
	-destination "platform=iOS Simulator,name=$DEVICE" \
	-showBuildSettings 2>/dev/null)

BUILT_PRODUCTS_DIR=$(echo "$SETTINGS" | awk -F' = ' '/ BUILT_PRODUCTS_DIR = /{print $2; exit}')
FULL_PRODUCT_NAME=$(echo "$SETTINGS" | awk -F' = ' '/ FULL_PRODUCT_NAME = /{print $2; exit}')
APP_PATH="$BUILT_PRODUCTS_DIR/$FULL_PRODUCT_NAME"

if [ ! -d "$APP_PATH" ]; then
	echo "Build succeeded but no app at: $APP_PATH" >&2
	exit 1
fi

# `simctl boot` fails on an already-booted device, which is not an error here.
echo "==> Booting $DEVICE"
xcrun simctl boot "$DEVICE" 2>/dev/null || true
open -a Simulator
# bootstatus prints a progress line per second; only its exit code matters.
xcrun simctl bootstatus "$DEVICE" >/dev/null

echo "==> Installing $FULL_PRODUCT_NAME"
xcrun simctl install "$DEVICE" "$APP_PATH"

echo "==> Launching $BUNDLE_ID"
xcrun simctl launch "$DEVICE" "$BUNDLE_ID"

cat <<'EOF'

Running. What a build cannot check for you:

  1. Settings -> Daily Reminder on -> DENY the prompt. The toggle must flip
     itself back off and offer "Open Settings". Then allow it, set the time a
     couple of minutes out, background the app, wait for the notification.
  2. Home screen -> pull down -> search today's puzzle title. The result must
     open the Archive detail, and must NOT show the answer or explanation.
  3. Shortcuts app -> "Today's Puzzle" and "Reveal Answer" should be listed.
     After a reveal the choices must be untappable; leaving the tab clears it.

Useful while poking at it:

  xcrun simctl launch --console-pty "DEVICE" com.beratsumer.kodkirintisi
  xcrun simctl privacy "DEVICE" reset all com.beratsumer.kodkirintisi
EOF
