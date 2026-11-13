#!/usr/bin/env bash
# Google Play screenshots in Polish and English, on a running emulator / phone, against a running
# API with an account that has some history.
#
#   SCREENSHOT_EMAIL=… SCREENSHOT_PASSWORD=… tool/store_screenshots.sh [device-id]
#   API_BASE_URL=https://… (optional; default: the emulator's view of the local API)
#
# The screen is set to 1080×1920 (Play wants at most 2:1) with a clean status bar (demo mode),
# and put back afterwards.
set -euo pipefail
cd "$(dirname "$0")/.."

: "${SCREENSHOT_EMAIL:?set SCREENSHOT_EMAIL}"
: "${SCREENSHOT_PASSWORD:?set SCREENSHOT_PASSWORD}"
DEVICE="${1:-emulator-5554}"
ADB="${ADB:-adb}"
export MSYS_NO_PATHCONV=1 # Git Bash on Windows: leave /sdcard-style paths alone

demo() { "$ADB" -s "$DEVICE" shell am broadcast -a com.android.systemui.demo -e command "$@" >/dev/null; }
cleanup() {
  "$ADB" -s "$DEVICE" shell wm size reset || true
  "$ADB" -s "$DEVICE" shell wm density reset || true
  demo exit || true
}
trap cleanup EXIT

"$ADB" -s "$DEVICE" shell wm size 1080x1920
"$ADB" -s "$DEVICE" shell wm density 420
"$ADB" -s "$DEVICE" shell settings put global sysui_demo_allowed 1
demo enter
demo clock -e hhmm 0930
demo battery -e level 100 -e plugged false
demo network -e wifi show -e level 4 -e mobile hide
demo notifications -e visible false

for locale in pl en; do
  echo "── $locale"
  SCREENSHOT_LOCALE=$locale flutter drive -d "$DEVICE" \
    --driver=test_driver/store_screenshots.dart \
    --target=integration_test/store_screenshots_test.dart \
    --dart-define=SCREENSHOT_LOCALE=$locale \
    --dart-define=SCREENSHOT_EMAIL="$SCREENSHOT_EMAIL" \
    --dart-define=SCREENSHOT_PASSWORD="$SCREENSHOT_PASSWORD" \
    ${API_BASE_URL:+--dart-define=API_BASE_URL=$API_BASE_URL}
done
echo "Done: fastlane/metadata/android/*/images/phoneScreenshots/"
