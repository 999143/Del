#!/usr/bin/env bash
set -euo pipefail

# Android emulator + browser-accessible desktop for an Ubuntu GitHub Codespace.
# Run from the Codespaces terminal: bash setup-android-phone.sh

SDK="$HOME/Android/Sdk"
TOOLS="$SDK/cmdline-tools/latest"
AVD_NAME="Pixel_API_35"
WORK="$HOME/android-phone"

echo "== 1/6: Installing system packages =="
sudo apt-get update
sudo apt-get install -y openjdk-21-jdk-headless wget unzip curl \
  xvfb x11vnc novnc websockify

echo "== 2/6: Downloading Android command-line tools =="
mkdir -p "$SDK/cmdline-tools" "$WORK"
TMP="$(mktemp -d)"
wget -q https://dl.google.com/android/repository/commandlinetools-linux-15859902_latest.zip \
  -O "$TMP/cmdline-tools.zip"
mkdir -p "$TMP/extracted"
unzip -q "$TMP/cmdline-tools.zip" -d "$TMP/extracted"
rm -rf "$TOOLS"
mkdir -p "$TOOLS"
cp -a "$TMP/extracted/cmdline-tools/." "$TOOLS/"
rm -rf "$TMP"

export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
export ANDROID_HOME="$SDK"
export ANDROID_SDK_ROOT="$SDK"
export PATH="$JAVA_HOME/bin:$SDK/cmdline-tools/latest/bin:$SDK/platform-tools:$SDK/emulator:$PATH"

echo "== 3/6: Installing emulator and Android image =="
yes | sdkmanager --licenses >/dev/null || true
sdkmanager --install \
  "platform-tools" \
  "emulator" \
  "platforms;android-35" \
  "system-images;android-35;google_apis;x86_64"

echo "== 4/6: Creating the virtual phone =="
echo "no" | avdmanager create avd \
  --name "$AVD_NAME" \
  --package "system-images;android-35;google_apis;x86_64" \
  --device "pixel_6" \
  --force

cat > "$WORK/start-phone.sh" <<'START'
#!/usr/bin/env bash
set -euo pipefail
SDK="$HOME/Android/Sdk"
AVD_NAME="Pixel_API_35"
WORK="$HOME/android-phone"
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
export ANDROID_HOME="$SDK"
export ANDROID_SDK_ROOT="$SDK"
export PATH="$JAVA_HOME/bin:$SDK/cmdline-tools/latest/bin:$SDK/platform-tools:$SDK/emulator:$PATH"

# Start a virtual display for the emulator's graphical phone window.
if ! pgrep -f "Xvfb :99" >/dev/null; then
  nohup Xvfb :99 -screen 0 430x900x24 -ac >"$WORK/xvfb.log" 2>&1 &
fi
export DISPLAY=:99
sleep 2

if ! pgrep -f "emulator.*-avd $AVD_NAME" >/dev/null; then
  nohup emulator -avd "$AVD_NAME" \
    -no-boot-anim -no-audio -gpu swiftshader \
    -camera-back none -camera-front none \
    >"$WORK/emulator.log" 2>&1 &
fi

# Expose the virtual display through browser-based VNC.
if ! pgrep -f "x11vnc.*5900" >/dev/null; then
  nohup x11vnc -display :99 -forever -shared -nopw -rfbport 5900 \
    >"$WORK/x11vnc.log" 2>&1 &
fi
if ! pgrep -f "novnc_proxy.*6080" >/dev/null; then
  nohup novnc_proxy --listen 6080 --vnc localhost:5900 \
    >"$WORK/novnc.log" 2>&1 &
fi

echo "Phone starting. Wait 1-3 minutes, then open Codespaces Ports."
echo "Forward port 6080 and open it in your browser."
START
chmod +x "$WORK/start-phone.sh"

echo "== 5/6: Creating a stop script =="
cat > "$WORK/stop-phone.sh" <<'STOP'
#!/usr/bin/env bash
pkill -f "emulator.*-avd Pixel_API_35" 2>/dev/null || true
pkill -f "x11vnc.*5900" 2>/dev/null || true
pkill -f "novnc_proxy.*6080" 2>/dev/null || true
pkill -f "Xvfb :99" 2>/dev/null || true
echo "Android phone services stopped."
STOP
chmod +x "$WORK/stop-phone.sh"

echo "== 6/6: Finished =="
echo
echo "Android emulator installed."
echo "To start the phone later, run: bash ~/android-phone/start-phone.sh"
echo "To stop it, run: bash ~/android-phone/stop-phone.sh"
