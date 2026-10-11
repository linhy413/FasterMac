// Copyright (c) 2026 linhy413.
// SPDX-License-Identifier: AGPL-3.0-only
// Section 7 attribution and origin terms: see ATTRIBUTION.md.
// Official project: https://github.com/linhy413/FasterMac

#import <Foundation/Foundation.h>

/// 光标晃动识别器（纯 C 结构，无窗口依赖，可独立单测）。
/// 语义：拖动期间光标在短时间内沿相反方向快速来回移动（晃动）时触发。
typedef struct {
    CGPoint lastPoint;
    BOOL hasLastPoint;
    CGPoint lastDirection;
    BOOL hasLastDirection;
    CGPoint strokeOrigin;
    BOOL hasStrokeOrigin;
    CGPoint lastReversalPoint;
    BOOL hasLastReversalPoint;
    double reversalTimestamps[4];
    NSUInteger reversalCount;
} QMDropShelfShakeDetector;

/// 判定参数（在窗口中必须保持足够短，避免把正常拖拽误判为晃动）。
static const double QMDropShelfShakeReversalWindow = 2.4;
static const double QMDropShelfShakeFirstSecondMaximumGap = 0.50;
static const NSUInteger QMDropShelfShakeRequiredReversals = 3;
static const double QMDropShelfShakeMinimumSegmentLength = 4.0;

static inline void QMDropShelfShakeDetectorInit(QMDropShelfShakeDetector *detector) {
    memset(detector, 0, sizeof(*detector));
}

/// 喂入一次拖动位置。返回 YES 表示刚刚检测到一次晃动（内部会复位，避免连续触发）。
static inline BOOL QMDropShelfShakeDetectorFeed(QMDropShelfShakeDetector *detector, CGPoint point, double now) {
    if (!detector->hasLastPoint) {
        detector->lastPoint = point;
        detector->hasLastPoint = YES;
        return NO;
    }

    CGPoint previousPoint = detector->lastPoint;
    CGPoint delta = CGPointMake(point.x - previousPoint.x, point.y - previousPoint.y);
    double length = sqrt(delta.x * delta.x + delta.y * delta.y);
    if (length < QMDropShelfShakeMinimumSegmentLength) {
        return NO;  // 忽略抖动，保留上次有效位置，防止漂移
    }
    detector->lastPoint = point;

    // 先清理滑动窗口外的旧反转时间戳。
    NSUInteger kept = 0;
    for (NSUInteger index = 0; index < detector->reversalCount; index++) {
        if (now - detector->reversalTimestamps[index] <= QMDropShelfShakeReversalWindow) {
            detector->reversalTimestamps[kept++] = detector->reversalTimestamps[index];
        }
    }
    detector->reversalCount = kept;

    CGPoint unitDirection = CGPointMake(delta.x / length, delta.y / length);
    if (detector->hasLastDirection) {
        // 用“从上一个回头点到当前位置”的整段弦向量作为主方向。
        // 相比只看相邻两帧，这不会在用户画圆滑 U 形时跟着圆弧一起转过去。
        CGPoint referenceDirection = detector->lastDirection;
        if (detector->hasStrokeOrigin) {
            CGPoint stroke = CGPointMake(previousPoint.x - detector->strokeOrigin.x,
                                         previousPoint.y - detector->strokeOrigin.y);
            double strokeLength = sqrt(stroke.x * stroke.x + stroke.y * stroke.y);
            if (strokeLength >= QMDropShelfShakeMinimumSegmentLength) {
                referenceDirection = CGPointMake(stroke.x / strokeLength, stroke.y / strokeLength);
            }
        }
        double dot = referenceDirection.x * unitDirection.x
            + referenceDirection.y * unitDirection.y;
        if (dot < -0.25) {
            // 方向反转：记录时间戳（环形，容量 4 足够）。
            // 第一次到第二次回头必须足够快；超时时把当前回头重新
            // 当作新手势的第一次，避免普通慢速转弯误触发聚合。
            if (detector->reversalCount == 1
                && now - detector->reversalTimestamps[0] > QMDropShelfShakeFirstSecondMaximumGap) {
                detector->reversalCount = 0;
            }
            if (detector->reversalCount < 4) {
                detector->reversalTimestamps[detector->reversalCount++] = now;
            } else {
                memmove(detector->reversalTimestamps,
                        detector->reversalTimestamps + 1,
                        sizeof(detector->reversalTimestamps[0]) * 3);
                detector->reversalTimestamps[3] = now;
            }
            detector->strokeOrigin = previousPoint;
            detector->hasStrokeOrigin = YES;
            detector->lastReversalPoint = previousPoint;
            detector->hasLastReversalPoint = YES;
            detector->lastDirection = unitDirection;
            if (detector->reversalCount >= QMDropShelfShakeRequiredReversals) {
                QMDropShelfShakeDetectorInit(detector);
                return YES;
            }
            return NO;
        }
        return NO;
    }
    detector->strokeOrigin = previousPoint;
    detector->hasStrokeOrigin = YES;
    detector->lastDirection = unitDirection;
    detector->hasLastDirection = YES;
    return NO;
}
