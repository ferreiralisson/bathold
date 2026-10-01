#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
swift build -c release
task_bin_dir=$(swift build -c release --show-bin-path)
task_app_dir="$PWD/dist/BatHold.app"
mkdir -p "$task_app_dir/Contents/MacOS"
mkdir -p "$task_app_dir/Contents/Resources/licenses" "$PWD/dist/licenses"
zsh scripts/build-icon.sh
cp "$PWD/dist/BatHold.icns" "$task_app_dir/Contents/Resources/BatHold.icns"
cp "$task_bin_dir/BatHold" "$task_app_dir/Contents/MacOS/BatHold"
cp "$task_bin_dir/bathold-cli" "$PWD/dist/bathold"
cp LICENSE THIRD_PARTY_NOTICES.md "$task_app_dir/Contents/Resources/"
cp licenses/*.txt "$task_app_dir/Contents/Resources/licenses/"
cp LICENSE THIRD_PARTY_NOTICES.md "$PWD/dist/"
cp licenses/*.txt "$PWD/dist/licenses/"
cat > "$task_app_dir/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>BatHold</string>
<key>CFBundleIdentifier</key><string>software.bathold.app</string>
<key>CFBundleName</key><string>BatHold</string>
<key>CFBundleIconFile</key><string>BatHold.icns</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$task_app_dir"
print "App local: $task_app_dir"
