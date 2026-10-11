#!/usr/bin/env bash
# Copyright (c) 2026 linhy413. SPDX-License-Identifier: AGPL-3.0-only
# Section 7 attribution and origin terms: see ATTRIBUTION.md.
set -euo pipefail

public_root="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/fastermac-public-tests.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT
public_include="$public_root/Sources/FasterMacKit"

xcrun clang -fobjc-arc "$public_root/Tests/QMSmartZipNamingTest.m" \
  "$public_include/Actions/QMSmartZipNaming.m" -I "$public_include" \
  -framework Foundation -o "$test_dir/SmartZipTest"
"$test_dir/SmartZipTest"
xcrun clang -fobjc-arc "$public_root/Tests/ScreenshotGeometryTest.m" \
  "$public_include/Capture/ScreenshotGeometry.m" -I "$public_include" \
  -framework AppKit -o "$test_dir/ScreenshotGeometryTest"
"$test_dir/ScreenshotGeometryTest"
echo "PASS: screenshot geometry"
xcrun clang -fobjc-arc "$public_root/Tests/DropShelfShakeDetectorTest.m" \
  -I "$public_include" -framework Foundation -framework CoreGraphics \
  -o "$test_dir/ShakeDetectorTest"
"$test_dir/ShakeDetectorTest"

# Build the documented public entry point and exercise the static-library link.
bash "$public_root/scripts/build.sh"
actual_name="$("$public_root/.build/smartzip-name" /tmp/品牌图_v1_001.jpg /tmp/品牌图_v1_002.png)"
[[ "$actual_name" == "品牌图" ]]
echo "PASS: documented command-line example"
