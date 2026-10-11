// Copyright (c) 2026 linhy413.
// SPDX-License-Identifier: AGPL-3.0-only
// Section 7 attribution and origin terms: see ATTRIBUTION.md.
// Official project: https://github.com/linhy413/FasterMac

#import <AppKit/AppKit.h>
#import "Capture/ScreenshotGeometry.h"
#import <assert.h>

static BOOL RectEqual(NSRect lhs, NSRect rhs) {
    return fabs(lhs.origin.x - rhs.origin.x) < 0.001 &&
           fabs(lhs.origin.y - rhs.origin.y) < 0.001 &&
           fabs(lhs.size.width - rhs.size.width) < 0.001 &&
           fabs(lhs.size.height - rhs.size.height) < 0.001;
}

int main(void) {
    @autoreleasepool {
        NSRect expected = NSMakeRect(10, 20, 50, 60);
        assert(RectEqual(QMScreenshotRectBetweenPoints(NSMakePoint(10, 20), NSMakePoint(60, 80)), expected));
        assert(RectEqual(QMScreenshotRectBetweenPoints(NSMakePoint(60, 80), NSMakePoint(10, 20)), expected));
        assert(RectEqual(QMScreenshotRectBetweenPoints(NSMakePoint(10, 80), NSMakePoint(60, 20)), expected));
        assert(RectEqual(QMScreenshotRectBetweenPoints(NSMakePoint(60, 20), NSMakePoint(10, 80)), expected));

        NSRect display = NSMakeRect(-1440, 0, 1440, 900);
        assert(NSEqualPoints(QMScreenshotClampPointToRect(NSMakePoint(-2000, 1200), display), NSMakePoint(-1440, 900)));
        assert(NSEqualPoints(QMScreenshotClampPointToRect(NSMakePoint(-720, 450), display), NSMakePoint(-720, 450)));

        NSRect localCapture = QMScreenshotDisplayLocalCaptureRect(NSMakeRect(-1200, 100, 500, 300), display);
        assert(RectEqual(localCapture, NSMakeRect(240, 500, 500, 300)));
        assert(NSIsEmptyRect(QMScreenshotDisplayLocalCaptureRect(NSMakeRect(100, 100, 50, 50), display)));

        NSSize nativePixels = QMScreenshotNativePixelSize(NSMakeSize(500, 300), 1.75, 2.0);
        assert(NSEqualSizes(nativePixels, NSMakeSize(875, 525)));
        NSSize fallbackPixels = QMScreenshotNativePixelSize(NSMakeSize(500, 300), 0.0, 2.0);
        assert(NSEqualSizes(fallbackPixels, NSMakeSize(1000, 600)));
        NSRect pixelCrop = QMScreenshotPixelCropRect(NSMakeRect(10.25, 20.5, 100.5, 50.25),
                                                     NSMakeSize(500, 300),
                                                     NSMakeSize(1000, 600));
        assert(RectEqual(pixelCrop, NSMakeRect(20, 41, 202, 101)));

        NSRect container = NSMakeRect(0, 0, 1000, 800);
        NSRect centeredBelow = QMScreenshotAccessoryFrame(NSMakeRect(350, 300, 300, 200), container, NSMakeSize(400, 44), 10);
        assert(RectEqual(centeredBelow, NSMakeRect(300, 246, 400, 44)));

        NSRect flippedAbove = QMScreenshotAccessoryFrame(NSMakeRect(10, 12, 120, 100), container, NSMakeSize(400, 44), 10);
        assert(RectEqual(flippedAbove, NSMakeRect(8, 122, 400, 44)));

        NSRect rightClamped = QMScreenshotAccessoryFrame(NSMakeRect(920, 300, 70, 100), container, NSMakeSize(400, 44), 10);
        assert(RectEqual(rightClamped, NSMakeRect(592, 246, 400, 44)));
    }
    return 0;
}
