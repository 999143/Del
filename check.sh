#!/usr/bin/env bash
echo "=== PROCESSES ==="
pgrep -af 'Xvfb|emulator|x11vnc|novnc|websockify' || true
echo
echo "=== ANDROID DEVICES ==="
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
adb devices -l 2>&1 || true
echo
echo "=== EMULATOR LOG (LAST 35 LINES) ==="
tail -n 35 "$HOME/android-phone/emulator.log" 2>&1 || true
echo
echo "=== X11VNC LOG (LAST 15 LINES) ==="
tail -n 15 "$HOME/android-phone/x11vnc.log" 2>&1 || true
echo
echo "=== PORTS ==="
ss -ltn 2>/dev/null | grep -E ':5900|:6080' || true
