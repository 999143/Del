#!/usr/bin/env bash
set -euo pipefail

START="$HOME/android-phone/start-phone.sh"

if [ ! -f "$START" ]; then
  echo "Cannot find $START"
  exit 1
fi

python3 - "$START" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text()
s = s.replace(
    "nohup novnc_proxy --listen 6080 --vnc localhost:5900",
    "nohup /usr/share/novnc/utils/novnc_proxy --listen 6080 --vnc localhost:5900"
)
p.write_text(s)
PY

chmod +x "$START"
echo "Fixed the noVNC launcher path."
echo "Starting Android phone services..."
bash "$START"
sleep 3

echo
if ss -ltn 2>/dev/null | grep -q ':6080'; then
  echo "SUCCESS: noVNC is listening on port 6080."
  echo "Open port 6080 from the Codespaces PORTS tab."
else
  echo "Port 6080 is not listening. Latest noVNC log:"
  cat "$HOME/android-phone/novnc.log" 2>/dev/null || echo "No noVNC log found."
fi
