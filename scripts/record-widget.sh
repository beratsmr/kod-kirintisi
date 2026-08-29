#!/bin/bash
#
# Records the interactive widget on the Home Screen and writes docs/widget.gif.
#
# The README's most persuasive claim is that you answer without opening the
# app, and only an animation actually shows that. Everything here is automated
# except one step: placing the widget on the Home Screen. There is no simctl
# command for it, and pretending otherwise by driving the widget gallery
# through synthesised taps would be far more fragile than asking.
#
#   ./scripts/record-widget.sh                  # iPhone 17 Pro, 15 seconds
#   ./scripts/record-widget.sh "iPhone 17" 20   # any device, any length
#
# The app is launched once with demo content first, so the widget shows a real
# streak instead of a first-run empty state — see `DemoContent`.

set -euo pipefail

DEVICE="${1:-iPhone 17 Pro}"
DURATION="${2:-15}"
BUNDLE_ID="com.beratsumer.kodkirintisi"
OUTPUT="docs/widget.gif"

cd "$(dirname "$0")/.."

# Build products and the raw recording are both throwaway, and neither belongs
# in the working tree — only the GIF is committed.
WORK_DIR="$(mktemp -d)"
RECORDING="$WORK_DIR/widget.mov"
DERIVED_DATA="$WORK_DIR/DerivedData"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "==> Generating project"
xcodegen generate

echo "==> Booting $DEVICE"
xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE" >/dev/null 2>&1 || true
open -a Simulator

echo "==> Building and installing"
xcodebuild build \
  -project KodKirintisi.xcodeproj \
  -scheme KodKirintisi \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  -derivedDataPath "$DERIVED_DATA" \
  -quiet

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/Kod Kırıntısı.app"
xcrun simctl install "$DEVICE" "$APP_PATH"

# Launching with the demo flag writes the shared container the widget reads,
# so the recording shows a streak rather than a blank first run. Terminating
# afterwards is what proves the point of the whole animation: the widget works
# with the app closed.
echo "==> Seeding demo content"
xcrun simctl launch "$DEVICE" "$BUNDLE_ID" "-KodKirintisiDemoContent" >/dev/null
sleep 3
xcrun simctl terminate "$DEVICE" "$BUNDLE_ID" >/dev/null 2>&1 || true

xcrun simctl status_bar "$DEVICE" override \
  --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100

cat <<'INSTRUCTIONS'

  ─────────────────────────────────────────────────────────────
  Manual step — there is no simctl equivalent for this.

  In the Simulator window:
    1. Go to the Home Screen and long-press an empty area.
    2. Tap "Edit" then "Add Widget", search for "Codestion".
    3. Add the medium widget and leave the Home Screen in edit mode
       by tapping Done.
    4. Make sure the app itself is closed (swipe it away in the
       app switcher) — the animation is meant to show the widget
       working on its own.
    5. Check that the widget shows a flame streak and an unanswered
       circle before going on. WidgetKit re-renders on its own
       schedule — several seconds after the container was seeded —
       so a widget added quickly can still be showing the old
       timeline. Wait for the streak to appear.

  Recording starts when you press Return. During the recording,
  tap one of the widget's answer buttons and let the result appear.
  Take your time: dead air before the tap is trimmed automatically.
  ─────────────────────────────────────────────────────────────

INSTRUCTIONS

read -r -p "Ready? Press Return to start recording. "

echo "==> Recording for ${DURATION}s"
xcrun simctl io "$DEVICE" recordVideo --codec h264 --force "$RECORDING" &
RECORD_PID=$!
sleep "$DURATION"
# simctl only finalises the file on SIGINT; killing it any harder leaves an
# unreadable stub behind.
kill -INT "$RECORD_PID"
wait "$RECORD_PID" 2>/dev/null || true

echo "==> Converting to GIF"
./scripts/movie-to-gif.swift "$RECORDING" "$OUTPUT" 10 420

xcrun simctl status_bar "$DEVICE" clear

echo
echo "Done. Check $OUTPUT — rerun with a different length if the timing is off."
