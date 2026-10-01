#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
task_iconset_dir="$PWD/dist/BatHold.iconset"
mkdir -p "$task_iconset_dir"
for task_size in 16 32 128 256 512; do
    sips -z "$task_size" "$task_size" Assets/AppIcon.png \
        --out "$task_iconset_dir/icon_${task_size}x${task_size}.png" >/dev/null
    task_retina_size=$((task_size * 2))
    sips -z "$task_retina_size" "$task_retina_size" Assets/AppIcon.png \
        --out "$task_iconset_dir/icon_${task_size}x${task_size}@2x.png" >/dev/null
done
iconutil -c icns "$task_iconset_dir" -o "$PWD/dist/BatHold.icns"
