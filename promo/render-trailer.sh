#!/bin/zsh
set -euo pipefail

format="${1:-iphone}"
project_root="${0:A:h:h}"
derived_data="/tmp/rabbit-hole-promo-derived"
app_path="$derived_data/Build/Products/Debug-iphonesimulator/Rabbit Hole.app"
bundle_id="Hakketjak.Rabbit-Hole"

if [[ "$format" == "iphone" ]]; then
  simulator_id="8AD5BC9B-1A68-4CC4-BB23-566E7736134A"
  width=886
  height=1920
  format_argument=()
elif [[ "$format" == "ipad" ]]; then
  simulator_id="215BFBED-C77F-4040-B6CF-258E7F010C43"
  width=1200
  height=1600
  format_argument=(-RabbitHolePromoFormat-ipad)
else
  print -u2 "usage: promo/render-trailer.sh iphone|ipad"
  exit 2
fi

capture_dir="$project_root/promo/captures/$format"
final_dir="$project_root/promo/final"
raw_video="$capture_dir/raw.mp4"
cues="$capture_dir/cues.json"
output="$final_dir/rabbit-hole-app-store-teaser-${width}x${height}.mp4"

mkdir -p "$capture_dir" "$final_dir"
xcodebuild -project "$project_root/Rabbit Hole.xcodeproj" \
  -scheme "Rabbit Hole" \
  -configuration Debug \
  -sdk iphonesimulator \
  -derivedDataPath "$derived_data" \
  CODE_SIGNING_ALLOWED=NO build

xcrun simctl bootstatus "$simulator_id" -b
xcrun simctl terminate "$simulator_id" "$bundle_id" 2>/dev/null || true
xcrun simctl uninstall "$simulator_id" "$bundle_id" 2>/dev/null || true
xcrun simctl install "$simulator_id" "$app_path"

xcrun simctl io "$simulator_id" recordVideo --codec=h264 --force "$raw_video" &
recorder_pid=$!
sleep 1
xcrun simctl launch "$simulator_id" "$bundle_id" -RabbitHolePromo "${format_argument[@]}"
container="$(xcrun simctl get_app_container "$simulator_id" "$bundle_id" data)"
done_marker="$container/Documents/rabbit-hole-promo-done.json"
ready_marker="$container/Documents/rabbit-hole-promo-ready.json"

while [[ ! -f "$done_marker" ]]; do sleep 1; done
kill -INT "$recorder_pid"
wait "$recorder_pid" || true

cp "$container/Documents/rabbit-hole-promo-cues-$format.json" "$cues"
cp "$ready_marker" "$capture_dir/ready.json"
cp "$done_marker" "$capture_dir/done.json"

created_epoch="$(swift -e 'import Foundation; let p=CommandLine.arguments[1]; let a=try! FileManager.default.attributesOfItem(atPath:p); print((a[.creationDate] as! Date).timeIntervalSince1970)' "$raw_video")"
started_epoch="$(plutil -extract startedAtEpoch raw -o - "$ready_marker")"
duration="$(plutil -extract elapsed raw -o - "$done_marker")"
trim="$(awk -v start="$started_epoch" -v created="$created_epoch" 'BEGIN { printf "%.6f", start-created }')"

swift "$project_root/promo/PromoPostprocess.swift" \
  "$raw_video" "$cues" "$output" "$trim" "$duration" \
  "$width" "$height" "$project_root/Rabbit Hole"

print "$output"
