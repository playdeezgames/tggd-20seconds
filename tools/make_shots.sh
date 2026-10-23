#!/usr/bin/env bash
# Screenshots of the real build with headless Chrome (needs a built build/web and a free port 8123).
# Writes assets/screenshots/01-title.png, 02-play.png, 03-epilogue.png (240x192 logical, scaled 3x).
set -euo pipefail
cd "$(dirname "$0")/.."
python3 -m http.server -d build/web 8123 >/dev/null 2>&1 &
srv=$!
trap 'kill $srv' EXIT
sleep 1
shot() { # name url virtual-time-ms
	google-chrome --headless=new --no-sandbox --disable-gpu --hide-scrollbars --window-size=720,576 \
		--virtual-time-budget="$3" --screenshot="assets/screenshots/$1.png" "$2" >/dev/null 2>&1
}
shot 01-title "http://localhost:8123/" 3000
shot 02-play "http://localhost:8123/#play=9" 3000
shot 03-epilogue "http://localhost:8123/#play=22.5" 3000
ls -l assets/screenshots
