#!/bin/bash
# Build and sign Reflection Pomodoro Timer.app
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/Reflection Pomodoro Timer.app"
MACOS="$APP/Contents/MacOS"
RESOURCES="$APP/Contents/Resources"

echo "Compiling PomodoroApp.swift..."
swiftc -o "$MACOS/PomodoroTimer" "$DIR/PomodoroApp.swift" -framework Cocoa -framework WebKit

echo "Copying resources..."
cp "$DIR/index.html" "$RESOURCES/index.html"

# Copy sound effects if they exist
if [ -d "$DIR/sound effect" ]; then
    mkdir -p "$RESOURCES/sound effect"
    cp "$DIR/sound effect/"*.mp3 "$RESOURCES/sound effect/" 2>/dev/null || true
fi

echo "Signing app..."
codesign --force --deep --sign - "$APP"

echo ""
echo "Build complete! Open with:"
echo "  open \"$APP\""
