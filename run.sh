#!/usr/bin/env bash
# รันแอปบน iOS Simulator หรือ Android Emulator
# ใช้งาน: ./run.sh ios | ./run.sh android  (ส่ง flag อื่นของ flutter run ต่อท้ายได้)
#         ./run.sh ios --boot-only        เปิด emulator/simulator อย่างเดียว (ใช้กับ VS Code preLaunchTask)
set -euo pipefail
cd "$(dirname "$0")"

PLATFORM="${1:-}"
shift || true

IOS_EMULATOR_ID="${IOS_EMULATOR_ID:-apple_ios_simulator}"
IOS_SIMULATOR_NAME="${IOS_SIMULATOR_NAME:-iPhone 18 Pro}"  # ต้องตรงกับ deviceId ใน .vscode/launch.json
ANDROID_EMULATOR_ID="${ANDROID_EMULATOR_ID:-test_pixel}"

find_device() {
  flutter devices --machine 2>/dev/null | python3 -c '
import json, sys
p = sys.argv[1]
devs = [d for d in json.load(sys.stdin) if d.get("emulator") and d["targetPlatform"].startswith(p)]
print(devs[0]["id"] if devs else "")
' "$1" 2>/dev/null || true
}

wait_for_device() {
  local pattern="$1"
  echo "⏳ รอ device ($pattern)..." >&2
  for _ in $(seq 1 60); do
    local id
    id=$(find_device "$pattern")
    if [[ -n "$id" ]]; then
      echo "$id"
      return 0
    fi
    sleep 3
  done
  echo "❌ ไม่พบ device หลังรอ 3 นาที" >&2
  exit 1
}

case "$PLATFORM" in
  ios)
    # เปิดเครื่องเฉพาะตอนที่ simulator ตัวนี้ยังไม่ได้บูต
    if ! xcrun simctl list devices booted | grep -q "$IOS_SIMULATOR_NAME ("; then
      xcrun simctl boot "$IOS_SIMULATOR_NAME" 2>/dev/null || true
      flutter emulators --launch "$IOS_EMULATOR_ID" || true
    fi
    DEVICE=$(wait_for_device "ios")
    ;;
  android)
    # เปิดเครื่องเฉพาะตอนที่ยังไม่มี emulator รันอยู่
    if [[ -z "$(find_device android)" ]]; then
      flutter emulators --launch "$ANDROID_EMULATOR_ID" || true
    fi
    DEVICE=$(wait_for_device "android")
    ;;
  *)
    echo "ใช้งาน: $0 ios|android [--boot-only | flutter run flags...]"
    exit 1
    ;;
esac

if [[ "${1:-}" == "--boot-only" ]]; then
  echo "✅ device พร้อม: $DEVICE"
  exit 0
fi

flutter pub get
echo "🚀 flutter run -d $DEVICE"
flutter run -d "$DEVICE" "$@"
