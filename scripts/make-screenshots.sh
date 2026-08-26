#!/bin/bash
#
# Regenerates the App Store screenshots in docs/screenshots/.
#
# The screenshots are captured from the shipping screens by a UI test rather
# than assembled by hand, so the listing cannot drift away from the app. The
# test runs against a fabricated answer history (see `DemoContent`) because a
# clean install has an empty archive and zeroed statistics.
#
#   ./scripts/make-screenshots.sh                     # iPhone 17 Pro Max
#   ./scripts/make-screenshots.sh "iPhone 17 Pro"     # any available device
#   ./scripts/make-screenshots.sh "iPhone 17 Pro" tr  # Turkish, for review only
#
# App Store Connect wants 6.9" screenshots, which is what the Pro Max renders,
# so that is the default. See `xcrun simctl list devices available` for the
# names on this machine.
#
# The listing is English, so only the English run writes to docs/screenshots.
# Other languages land in a temporary directory and are printed — the point of
# those is to see all four screens translated in one pass, not to ship them.

set -euo pipefail

DEVICE="${1:-iPhone 17 Pro Max}"
LANGUAGE="${2:-en}"
SCHEME="Screenshots"

cd "$(dirname "$0")/.."

case "$LANGUAGE" in
  en)
    OUTPUT_DIR="docs/screenshots"
    TEST="KodKirintisiUITests/ScreenshotTests/testCaptureScreenshots"
    ;;
  tr)
    OUTPUT_DIR="$(mktemp -d)/$LANGUAGE"
    TEST="KodKirintisiUITests/ScreenshotTests/testCaptureTurkishScreenshots"
    ;;
  *)
    echo "Unknown language '$LANGUAGE' — the app ships en and tr." >&2
    exit 1
    ;;
esac

RESULT_BUNDLE="$(mktemp -d)/Screenshots.xcresult"
# xcodebuild refuses to write a result bundle that already exists, and mktemp
# -d has already created the parent, so only the leaf must be absent.
trap 'rm -rf "$(dirname "$RESULT_BUNDLE")"' EXIT

echo "==> Generating project"
xcodegen generate

# A fixed status bar is the difference between a store screenshot and a
# screenshot of somebody's phone. Apple's own listings use 9:41.
echo "==> Booting $DEVICE"
xcrun simctl boot "$DEVICE" 2>/dev/null || true
# Already-booted devices make this exit non-zero after printing a screenful of
# progress, and xcodebuild waits for the device anyway.
xcrun simctl bootstatus "$DEVICE" >/dev/null 2>&1 || true
xcrun simctl status_bar "$DEVICE" override \
  --time "9:41" \
  --dataNetwork wifi \
  --wifiMode active \
  --wifiBars 3 \
  --cellularMode active \
  --cellularBars 4 \
  --batteryState charged \
  --batteryLevel 100

echo "==> Running the capture"
xcodebuild test \
  -project KodKirintisi.xcodeproj \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  -resultBundlePath "$RESULT_BUNDLE" \
  -only-testing:"$TEST" \
  -quiet

echo "==> Extracting attachments"
EXPORT_DIR="$(mktemp -d)"
xcrun xcresulttool export attachments \
  --path "$RESULT_BUNDLE" \
  --output-path "$EXPORT_DIR"

# The exported files carry generated names; manifest.json maps each back to the
# name the test gave it, which is what makes the output stable across runs.
mkdir -p "$OUTPUT_DIR"
python3 - "$EXPORT_DIR" "$OUTPUT_DIR" <<'PYTHON'
import json, pathlib, shutil, sys

export_dir, output_dir = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
manifest = json.loads((export_dir / "manifest.json").read_text())

count = 0
for test in manifest:
    for attachment in test.get("attachments", []):
        name = attachment.get("suggestedHumanReadableName") or attachment["exportedFileName"]
        source = export_dir / attachment["exportedFileName"]
        # The test names its attachments "01-today" and so on; anything else is
        # something Xcode added on its own and is not part of the listing.
        if not name[:2].isdigit():
            continue
        # Xcode appends "_0_<uuid>.png" to the name the test gave. Keeping only
        # the part before the first underscore is what makes the committed
        # filenames stable, so regenerating produces a reviewable diff rather
        # than five renamed files.
        shutil.copyfile(source, output_dir / f"{name.split('_', 1)[0]}.png")
        count += 1

if count == 0:
    sys.exit("No screenshots found in the result bundle.")
print(f"Wrote {count} screenshots to {output_dir}")
PYTHON

echo "==> Restoring the status bar"
xcrun simctl status_bar "$DEVICE" clear

echo
if [ "$LANGUAGE" = "en" ]; then
  echo "Done. Review $OUTPUT_DIR before committing — these go on the store page."
else
  echo "Done. $LANGUAGE screenshots are in $OUTPUT_DIR — for review, not for committing."
fi
