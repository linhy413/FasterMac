// Copyright (c) 2026 linhy413.
// SPDX-License-Identifier: AGPL-3.0-only
// Section 7 attribution and origin terms: see ATTRIBUTION.md.
// Official project: https://github.com/linhy413/FasterMac

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Returns a positive-width/height rectangle for a drag in any direction.
FOUNDATION_EXPORT NSRect QMScreenshotRectBetweenPoints(NSPoint first, NSPoint second);

/// Clamps a point to the closed bounds of a display rectangle.
FOUNDATION_EXPORT NSPoint QMScreenshotClampPointToRect(NSPoint point, NSRect bounds);

/// Converts an AppKit screen-space rectangle (bottom-left origin) into the
/// selected display's local capture coordinates (top-left origin).
FOUNDATION_EXPORT NSRect QMScreenshotDisplayLocalCaptureRect(NSRect screenRect,
                                                             NSRect displayFrame);

/// Converts a logical point size to native capture pixels. ScreenCaptureKit's
/// content-filter scale wins because it describes the actual capture surface;
/// the AppKit backing scale is only a compatibility fallback.
FOUNDATION_EXPORT NSSize QMScreenshotNativePixelSize(NSSize logicalSize,
                                                      CGFloat pointPixelScale,
                                                      CGFloat fallbackBackingScale);

/// Maps a display-local logical rect (top-left origin) into the pixel bounds
/// of a full-display snapshot without introducing resampling.
FOUNDATION_EXPORT NSRect QMScreenshotPixelCropRect(NSRect logicalRect,
                                                   NSSize displayLogicalSize,
                                                   NSSize snapshotPixelSize);

/// Places an accessory below the selection when possible, otherwise above it,
/// while keeping the complete accessory inside the supplied container.
FOUNDATION_EXPORT NSRect QMScreenshotAccessoryFrame(NSRect selection,
                                                    NSRect container,
                                                    NSSize accessorySize,
                                                    CGFloat gap);

NS_ASSUME_NONNULL_END
