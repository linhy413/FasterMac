#!/usr/bin/env bash
# Copyright (c) 2026 linhy413. SPDX-License-Identifier: AGPL-3.0-only
# Section 7 attribution and origin terms: see ATTRIBUTION.md.
set -euo pipefail

public_root="$(cd "$(dirname "$0")/.." && pwd)"
output_dir="$public_root/.build"
mkdir -p "$output_dir"
public_include="$public_root/Sources/FasterMacKit"

xcrun clang -fobjc-arc -Wall -Wextra -c \
  "$public_include/Actions/QMSmartZipNaming.m" \
  -I "$public_include" -o "$output_dir/QMSmartZipNaming.o"
xcrun clang -fobjc-arc -Wall -Wextra -c \
  "$public_include/Capture/ScreenshotGeometry.m" \
  -I "$public_include" -o "$output_dir/ScreenshotGeometry.o"
xcrun libtool -static \
  "$output_dir/QMSmartZipNaming.o" "$output_dir/ScreenshotGeometry.o" \
  -o "$output_dir/libFasterMacKit.a"
xcrun clang -fobjc-arc -Wall -Wextra \
  "$public_root/Examples/smartzip-name.m" \
  "$output_dir/libFasterMacKit.a" -I "$public_include" \
  -framework Foundation -framework AppKit -o "$output_dir/smartzip-name"
echo "Built .build/libFasterMacKit.a and .build/smartzip-name"
