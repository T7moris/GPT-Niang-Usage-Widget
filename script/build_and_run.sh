#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-run}"
APP_NAME="GPTNiangMac"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
case "$MODE" in run|--verify|--debug|--logs|--telemetry|--build-only) ;; *) echo "Usage: $0 [--build-only|--verify|--debug|--logs|--telemetry]" >&2; exit 2 ;; esac
if [ "$MODE" != --build-only ]; then pkill -x "$APP_NAME" >/dev/null 2>&1 || true; fi
TASK_CACHE="${GPT_NIANG_BUILD_CACHE:-$ROOT_DIR/macos/.build-cache}"
mkdir -p "$TASK_CACHE/clang" "$TASK_CACHE/swiftpm"
export CLANG_MODULE_CACHE_PATH="$TASK_CACHE/clang"
export SWIFTPM_MODULECACHE_OVERRIDE="$TASK_CACHE/clang"
swift build --package-path "$ROOT_DIR/macos" --disable-sandbox --cache-path "$TASK_CACHE/swiftpm"
BIN_DIR="$(swift build --package-path "$ROOT_DIR/macos" --disable-sandbox --cache-path "$TASK_CACHE/swiftpm" --show-bin-path)"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources/Backend/runtime" "$APP_BUNDLE/Contents/Resources/Backend/.codex-plugin"
cp "$BIN_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$ROOT_DIR/gpt-niang-usage/runtime/"*.mjs "$APP_BUNDLE/Contents/Resources/Backend/runtime/"
cp "$ROOT_DIR/gpt-niang-usage/.codex-plugin/plugin.json" "$APP_BUNDLE/Contents/Resources/Backend/.codex-plugin/"
cp "$ROOT_DIR/gpt-niang-usage/assets/gpt-dragon-niang-bust.png" "$ROOT_DIR/gpt-niang-usage/assets/press.wav" "$ROOT_DIR/gpt-niang-usage/assets/release.wav" "$ROOT_DIR/gpt-niang-usage/assets/quotes.json" "$APP_BUNDLE/Contents/Resources/"
cp "$ROOT_DIR/LICENSE" "$APP_BUNDLE/Contents/Resources/LICENSE"
cat > "$APP_BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>GPTNiangMac</string>
<key>CFBundleIdentifier</key><string>io.github.t7moris.GPTNiangMac</string>
<key>CFBundleName</key><string>GPT 娘</string>
<key>CFBundleDisplayName</key><string>GPT 娘</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.2.5</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
# iCloud/Finder can add presentation metadata to generated bundles.
/usr/bin/xattr -rd com.apple.FinderInfo "$APP_BUNDLE" 2>/dev/null || true
/usr/bin/xattr -rd com.apple.ResourceFork "$APP_BUNDLE" 2>/dev/null || true
/usr/bin/codesign --force --deep --sign - "$APP_BUNDLE"
open_app() { /usr/bin/open -n "$APP_BUNDLE" --args "${@:2}"; }

case "$MODE" in
  --build-only) echo "Built $APP_BUNDLE" ;;
  --debug) lldb -- "$APP_BUNDLE/Contents/MacOS/$APP_NAME" ;;
  --logs) open_app "$@"; /usr/bin/log stream --info --style compact --predicate 'process == "GPTNiangMac"' ;;
  --telemetry) open_app "$@"; /usr/bin/log stream --info --style compact --predicate 'subsystem == "io.github.t7moris.GPTNiangMac"' ;;
  --verify) open_app "$@"; sleep 2; pgrep -x "$APP_NAME" >/dev/null; echo "Verified app process" ;;
  run) open_app "$@" ;;
esac
