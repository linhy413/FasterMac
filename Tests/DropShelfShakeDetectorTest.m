// Copyright (c) 2026 linhy413.
// SPDX-License-Identifier: AGPL-3.0-only
// Section 7 attribution and origin terms: see ATTRIBUTION.md.
// Official project: https://github.com/linhy413/FasterMac

#import <Foundation/Foundation.h>
#import "Windows/DropShelfShakeDetector.h"

static void QMRequire(BOOL condition, NSString *message) {
    if (condition) { return; }
    NSLog(@"FAIL: %@", message);
    exit(1);
}

int main(void) {
    @autoreleasepool {
        // 快速来回晃动：0.1s 间隔内 4 段方向交替 → 第 4 段触发。
        {
            QMDropShelfShakeDetector detector;
            QMDropShelfShakeDetectorInit(&detector);
            double t = 0;
            BOOL triggered = NO;
            triggered = QMDropShelfShakeDetectorFeed(&detector, CGPointMake(0, 0), t += 0.1);
            QMRequire(!triggered, @"first point must not trigger");
            triggered = QMDropShelfShakeDetectorFeed(&detector, CGPointMake(20, 0), t += 0.1);
            QMRequire(!triggered, @"first segment must not trigger");
            triggered = QMDropShelfShakeDetectorFeed(&detector, CGPointMake(0, 0), t += 0.1);
            QMRequire(!triggered, @"single reversal must not trigger");
            triggered = QMDropShelfShakeDetectorFeed(&detector, CGPointMake(20, 0), t += 0.1);
            QMRequire(!triggered, @"two reversals must not trigger");
            triggered = QMDropShelfShakeDetectorFeed(&detector, CGPointMake(0, 0), t += 0.1);
            QMRequire(triggered, @"three reversals inside the window must trigger a shake");
            // 触发后自动复位：下一次单次反转不应再次触发。
            triggered = QMDropShelfShakeDetectorFeed(&detector, CGPointMake(20, 0), t += 0.1);
            QMRequire(!triggered, @"detector must reset after triggering");
        }

        // 圆滑的 U 形回头：即使相邻两小段不是 180°，也应相对整段主方向
        // 在第一次快速回头时立即记录一次反转。
        {
            QMDropShelfShakeDetector detector;
            QMDropShelfShakeDetectorInit(&detector);
            double t = 0;
            NSArray<NSValue *> *points = @[
                [NSValue valueWithPoint:NSMakePoint(0, 0)],
                [NSValue valueWithPoint:NSMakePoint(12, 0)],
                [NSValue valueWithPoint:NSMakePoint(24, 2)],
                [NSValue valueWithPoint:NSMakePoint(30, 8)],
                [NSValue valueWithPoint:NSMakePoint(28, 15)],
                [NSValue valueWithPoint:NSMakePoint(18, 18)]
            ];
            for (NSValue *value in points) {
                QMDropShelfShakeDetectorFeed(&detector, value.pointValue, t += 0.08);
            }
            QMRequire(detector.reversalCount == 1,
                      @"a smooth U-turn must immediately count as the first reversal");
        }

        // 第一次和第二次回头相隔过久时，第二次应重新算作新手势的
        // 第一次，不能进入聚合确认阶段。
        {
            QMDropShelfShakeDetector detector;
            QMDropShelfShakeDetectorInit(&detector);
            double t = 0;
            QMDropShelfShakeDetectorFeed(&detector, CGPointMake(0, 0), t += 0.1);
            QMDropShelfShakeDetectorFeed(&detector, CGPointMake(20, 0), t += 0.1);
            QMDropShelfShakeDetectorFeed(&detector, CGPointMake(0, 0), t += 0.1);
            QMRequire(detector.reversalCount == 1, @"the first reversal must be recorded");
            QMDropShelfShakeDetectorFeed(&detector, CGPointMake(20, 0), t += 0.6);
            QMRequire(detector.reversalCount == 1,
                      @"a late second reversal must restart instead of confirming the gesture");
        }

        // 截图中较长的往返路径可跨越 1.2s，但三次回头仍应在放宽后的
        // 2.4s 手势窗口内触发架子。
        {
            QMDropShelfShakeDetector detector;
            QMDropShelfShakeDetectorInit(&detector);
            double t = 0;
            BOOL triggered = NO;
            triggered = QMDropShelfShakeDetectorFeed(&detector, CGPointMake(0, 0), t += 0.4);
            triggered = QMDropShelfShakeDetectorFeed(&detector, CGPointMake(80, 0), t += 0.4);
            triggered = QMDropShelfShakeDetectorFeed(&detector, CGPointMake(0, 0), t += 0.4);
            triggered = QMDropShelfShakeDetectorFeed(&detector, CGPointMake(80, 0), t += 0.4);
            triggered = QMDropShelfShakeDetectorFeed(&detector, CGPointMake(0, 0), t += 0.4);
            QMRequire(triggered, @"three long-path reversals inside 2.4 seconds must trigger");
        }

        // 慢速往返：三次反转无法同时保留在 2.4s 滑动窗口内，不触发。
        {
            QMDropShelfShakeDetector detector;
            QMDropShelfShakeDetectorInit(&detector);
            double t = 0;
            BOOL triggered = NO;
            QMDropShelfShakeDetectorFeed(&detector, CGPointMake(0, 0), t += 2.0);
            QMDropShelfShakeDetectorFeed(&detector, CGPointMake(20, 0), t += 2.0);
            QMDropShelfShakeDetectorFeed(&detector, CGPointMake(0, 0), t += 2.0);
            QMDropShelfShakeDetectorFeed(&detector, CGPointMake(20, 0), t += 2.0);
            triggered = QMDropShelfShakeDetectorFeed(&detector, CGPointMake(0, 0), t += 2.0);
            QMRequire(!triggered, @"reversals outside the sliding window must not trigger");
        }

        // 2pt 抖动：低于最小段长，不触发。
        {
            QMDropShelfShakeDetector detector;
            QMDropShelfShakeDetectorInit(&detector);
            double t = 0;
            BOOL triggered = NO;
            for (int i = 0; i < 8; i++) {
                triggered = QMDropShelfShakeDetectorFeed(&detector, CGPointMake(i % 2 ? 2.0 : 0.0, 0), t += 0.05);
            }
            QMRequire(!triggered, @"sub-threshold jitter must not trigger");
        }

        printf("PASS: drop shelf shake detector recognizes rapid reversals, ignores slow drags and jitter\n");
    }
    return 0;
}
