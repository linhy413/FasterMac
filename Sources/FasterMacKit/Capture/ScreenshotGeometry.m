// Copyright (c) 2026 linhy413.
// SPDX-License-Identifier: AGPL-3.0-only
// Section 7 attribution and origin terms: see ATTRIBUTION.md.
// Official project: https://github.com/linhy413/FasterMac

#import "ScreenshotGeometry.h"

NSRect QMScreenshotRectBetweenPoints(NSPoint first, NSPoint second) {
    CGFloat minX = MIN(first.x, second.x);
    CGFloat minY = MIN(first.y, second.y);
    CGFloat maxX = MAX(first.x, second.x);
    CGFloat maxY = MAX(first.y, second.y);
    return NSMakeRect(minX, minY, maxX - minX, maxY - minY);
}

NSPoint QMScreenshotClampPointToRect(NSPoint point, NSRect bounds) {
    return NSMakePoint(MAX(NSMinX(bounds), MIN(NSMaxX(bounds), point.x)),
                       MAX(NSMinY(bounds), MIN(NSMaxY(bounds), point.y)));
}

NSRect QMScreenshotDisplayLocalCaptureRect(NSRect screenRect, NSRect displayFrame) {
    NSRect clipped = NSIntersectionRect(screenRect, displayFrame);
    if (NSIsEmptyRect(clipped)) { return NSZeroRect; }
    return NSMakeRect(NSMinX(clipped) - NSMinX(displayFrame),
                      NSMaxY(displayFrame) - NSMaxY(clipped),
                      NSWidth(clipped),
                      NSHeight(clipped));
}

NSSize QMScreenshotNativePixelSize(NSSize logicalSize,
                                   CGFloat pointPixelScale,
                                   CGFloat fallbackBackingScale) {
    CGFloat scale = pointPixelScale > 0.0 ? pointPixelScale : MAX(1.0, fallbackBackingScale);
    return NSMakeSize(MAX(1.0, (CGFloat)llround(logicalSize.width * scale)),
                      MAX(1.0, (CGFloat)llround(logicalSize.height * scale)));
}

NSRect QMScreenshotPixelCropRect(NSRect logicalRect,
                                 NSSize displayLogicalSize,
                                 NSSize snapshotPixelSize) {
    if (displayLogicalSize.width <= 0.0 || displayLogicalSize.height <= 0.0 ||
        snapshotPixelSize.width <= 0.0 || snapshotPixelSize.height <= 0.0) {
        return NSZeroRect;
    }
    CGFloat scaleX = snapshotPixelSize.width / displayLogicalSize.width;
    CGFloat scaleY = snapshotPixelSize.height / displayLogicalSize.height;
    CGFloat minimumX = floor(NSMinX(logicalRect) * scaleX);
    CGFloat minimumY = floor(NSMinY(logicalRect) * scaleY);
    CGFloat maximumX = ceil(NSMaxX(logicalRect) * scaleX);
    CGFloat maximumY = ceil(NSMaxY(logicalRect) * scaleY);
    NSRect pixels = NSMakeRect(minimumX,
                               minimumY,
                               maximumX - minimumX,
                               maximumY - minimumY);
    return NSIntersectionRect(pixels, NSMakeRect(0, 0, snapshotPixelSize.width, snapshotPixelSize.height));
}

NSRect QMScreenshotAccessoryFrame(NSRect selection,
                                  NSRect container,
                                  NSSize accessorySize,
                                  CGFloat gap) {
    static const CGFloat padding = 8.0;
    CGFloat minX = NSMinX(container) + padding;
    CGFloat maxX = NSMaxX(container) - padding - accessorySize.width;
    CGFloat x = NSMidX(selection) - accessorySize.width / 2.0;
    if (maxX < minX) {
        x = NSMidX(container) - accessorySize.width / 2.0;
    } else {
        x = MAX(minX, MIN(maxX, x));
    }

    CGFloat minimumY = NSMinY(container) + padding;
    CGFloat maximumY = NSMaxY(container) - padding - accessorySize.height;
    CGFloat belowY = NSMinY(selection) - gap - accessorySize.height;
    CGFloat aboveY = NSMaxY(selection) + gap;
    CGFloat y = belowY >= minimumY ? belowY : aboveY;
    if (maximumY < minimumY) {
        y = NSMidY(container) - accessorySize.height / 2.0;
    } else {
        y = MAX(minimumY, MIN(maximumY, y));
    }
    return NSMakeRect(x, y, accessorySize.width, accessorySize.height);
}
