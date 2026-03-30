#!/bin/bash
# Build and sign Reflection Pomodoro Timer.app
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/Reflection Pomodoro Timer.app"
MACOS="$APP/Contents/MacOS"
RESOURCES="$APP/Contents/Resources"
INSTALL_DIR="/Applications"

# GitHub zip includes a partial .app without Contents/MacOS; swiftc cannot create the binary if the dir is missing.
mkdir -p "$MACOS" "$RESOURCES"

echo "Compiling PomodoroApp.swift..."
swiftc -o "$MACOS/PomodoroTimer" "$DIR/PomodoroApp.swift" -framework Cocoa -framework WebKit

echo "Copying resources..."
cp "$DIR/index.html" "$RESOURCES/index.html"
cp "$DIR/AppIcon.icns" "$RESOURCES/AppIcon.icns" 2>/dev/null || true

# Copy sound effects if they exist
if [ -d "$DIR/sound effect" ]; then
    mkdir -p "$RESOURCES/sound effect"
    cp "$DIR/sound effect/"*.mp3 "$RESOURCES/sound effect/" 2>/dev/null || true
fi

echo "Signing app..."
codesign --force --deep --sign - "$APP"

# Install to Applications (skipped when the menu bar app runs an in-place update)
if [ "${POMODORO_SKIP_INSTALL:-}" = "1" ]; then
  echo "POMODORO_SKIP_INSTALL=1 — skipping copy to $INSTALL_DIR (caller replaces running bundle)."
else
  echo "Installing to $INSTALL_DIR..."
  cp -R "$APP" "$INSTALL_DIR/"
  xattr -cr "$INSTALL_DIR/Reflection Pomodoro Timer.app"
  codesign --force --deep --sign - "$INSTALL_DIR/Reflection Pomodoro Timer.app"
fi

echo ""
echo "Build complete! Open with:"
echo "  open \"$INSTALL_DIR/Reflection Pomodoro Timer.app\""
