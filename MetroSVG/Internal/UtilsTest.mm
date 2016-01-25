/*
 * Copyright 2016 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <XCTest/XCTest.h>

#import <CoreGraphics/CoreGraphics.h>

#include "MetroSVG/Internal/Constants.h"
#include "MetroSVG/Internal/Utils.h"

using namespace metrosvg::internal;

static const CGFloat kTolerance = 0.001f;

#define AssertCGPointEqualWithAccurary(point1, point2, tolerance) { \
  XCTAssertEqualWithAccuracy(point1.x, point2.x, tolerance); \
  XCTAssertEqualWithAccuracy(point1.y, point2.y, tolerance); \
}

#define AssertCGSizeEqualWithAccurary(size1, size2, tolerance) { \
  XCTAssertEqualWithAccuracy(size1.width, size2.width, tolerance); \
  XCTAssertEqualWithAccuracy(size1.height, size2.height, tolerance); \
}

#define AssertCGRectEqualWithAccurary(rect1, rect2, tolerance) { \
  AssertCGPointEqualWithAccurary(rect1.origin, rect2.origin, tolerance); \
  AssertCGSizeEqualWithAccurary(rect1.size, rect2.size, tolerance); \
}

#define AssertCGAffineTransformEqual(transform1, transform2) { \
  XCTAssertEqualWithAccuracy(transform1.a, transform2.a, kTolerance); \
  XCTAssertEqualWithAccuracy(transform1.b, transform2.b, kTolerance); \
  XCTAssertEqualWithAccuracy(transform1.c, transform2.c, kTolerance); \
  XCTAssertEqualWithAccuracy(transform1.d, transform2.d, kTolerance); \
  XCTAssertEqualWithAccuracy(transform1.tx, transform2.tx, kTolerance); \
  XCTAssertEqualWithAccuracy(transform1.ty, transform2.ty, kTolerance); \
}

static CGAffineTransform UniformScaleThenTranslate(CGFloat scale,
                                                   CGFloat tx,
                                                   CGFloat ty) {
  return CGAffineTransformScale(
      CGAffineTransformMakeTranslation(tx, ty), scale, scale);
}

@interface UtilsTest : XCTestCase
@end

@implementation UtilsTest

- (void)testClampToUnitRange_TooLow {
  CGFloat value = -55.0;
  CGFloat clampedValue = ClampToUnitRange(value);
  XCTAssertEqualWithAccuracy(clampedValue, 0.0, kTolerance);
}

- (void)testClampToUnitRange_Bottom {
  CGFloat value = 0.0;
  CGFloat clampedValue = ClampToUnitRange(value);
  XCTAssertEqualWithAccuracy(value, clampedValue, kTolerance);
}

- (void)testClampToUnitRange_Mid {
  CGFloat value = 0.5;
  CGFloat clampedValue = ClampToUnitRange(value);
  XCTAssertEqualWithAccuracy(value, clampedValue, kTolerance);
}

- (void)testClampToUnitRange_Top {
  CGFloat value = 1.0;
  CGFloat clampedValue = ClampToUnitRange(value);
  XCTAssertEqualWithAccuracy(value, clampedValue, kTolerance);
}

- (void)testClampToUnitRange_TooHigh {
  CGFloat value = 5.0;
  CGFloat clampedValue = ClampToUnitRange(value);
  XCTAssertEqualWithAccuracy(clampedValue, 1.0, kTolerance);
}

- (void)testSvgArcToCgArc_Large1Sweep0 {
  CGPoint start_point = CGPointMake(40.0, 0.0);
  CGPoint end_point = CGPointMake(60.0, 20.0);
  CGFloat radius = 20.0;
  CGPoint center = CGPointZero;
  CGFloat start_angle = 0.0;
  CGFloat end_angle = 0.0;
  XCTAssertTrue(SvgArcToCgArc(start_point, end_point, true, false,
                              &radius, &center, &start_angle, &end_angle));
  XCTAssertEqualWithAccuracy(center.x, 40.0, kTolerance);
  XCTAssertEqualWithAccuracy(center.y, 20.0, kTolerance);
  XCTAssertTrue(AreAnglesClose(start_angle, -kPi / 2, kTolerance));
  XCTAssertTrue(AreAnglesClose(end_angle, 0.0, kTolerance));
}

- (void)testSvgArcToCgArc_Large1Sweep1 {
  CGPoint start_point = CGPointMake(40.0, 0.0);
  CGPoint end_point = CGPointMake(60.0, 20.0);
  CGFloat radius = 20.0;
  CGPoint center = CGPointZero;
  CGFloat start_angle = 0.0;
  CGFloat end_angle = 0.0;
  XCTAssertTrue(SvgArcToCgArc(start_point, end_point, true, true,
                              &radius, &center, &start_angle, &end_angle));
  XCTAssertEqualWithAccuracy(center.x, 60.0, kTolerance);
  XCTAssertEqualWithAccuracy(center.y, 0.0, kTolerance);
  XCTAssertTrue(AreAnglesClose(start_angle, -kPi, kTolerance));
  XCTAssertTrue(AreAnglesClose(end_angle, kPi / 2, kTolerance));
}

- (void)testSvgArcToCgArc_Large0Sweep0 {
  CGPoint start_point = CGPointMake(40.0, 0.0);
  CGPoint end_point = CGPointMake(60.0, 20.0);
  CGFloat radius= 20.0;
  CGPoint center = CGPointZero;
  CGFloat start_angle = 0.0;
  CGFloat end_angle = 0.0;
  XCTAssertTrue(SvgArcToCgArc(start_point, end_point, false, false,
                              &radius, &center, &start_angle, &end_angle));
  XCTAssertEqualWithAccuracy(center.x, 60.0, kTolerance);
  XCTAssertEqualWithAccuracy(center.y, 0.0, kTolerance);
  XCTAssertTrue(AreAnglesClose(start_angle, -kPi, kTolerance));
  XCTAssertTrue(AreAnglesClose(end_angle, kPi / 2, kTolerance));
}

- (void)testSvgArcToCgArc_Large0Sweep1 {
  CGPoint start_point = CGPointMake(40.0, 0.0);
  CGPoint end_point = CGPointMake(60.0, 20.0);
  CGFloat radius = 20.0;
  CGPoint center = CGPointZero;
  CGFloat start_angle = 0.0;
  CGFloat end_angle = 0.0;
  XCTAssertTrue(SvgArcToCgArc(start_point, end_point, false, true,
                              &radius, &center, &start_angle, &end_angle));
  XCTAssertEqualWithAccuracy(center.x, 40.0, kTolerance);
  XCTAssertEqualWithAccuracy(center.y, 20.0, kTolerance);
  XCTAssertTrue(AreAnglesClose(start_angle, -kPi / 2, kTolerance));
  XCTAssertTrue(AreAnglesClose(end_angle, 0.0, kTolerance));
}

- (void)testSvgArcToCgArcVertical_Large0Sweep1 {
  CGPoint start_point = CGPointMake(20.0, 40.0);
  CGPoint end_point = CGPointMake(60.0, 40.0);
  CGFloat radius = 20.0;
  CGPoint center = CGPointZero;
  CGFloat start_angle = 0.0;
  CGFloat end_angle = 0.0;
  XCTAssertTrue(SvgArcToCgArc(start_point, end_point, false, true,
                              &radius, &center, &start_angle, &end_angle));
  XCTAssertEqualWithAccuracy(center.x, 40.0, kTolerance);
  XCTAssertEqualWithAccuracy(center.y, 40.0, kTolerance);
  XCTAssertTrue(AreAnglesClose(start_angle, kPi, kTolerance));
  XCTAssertTrue(AreAnglesClose(end_angle, 0.0, kTolerance));
}

- (void)testSvgArcToCgArcHorizontal_Large0Sweep1 {
  CGPoint start_point = CGPointMake(40.0, 20.0);
  CGPoint end_point = CGPointMake(40.0, 60.0);
  CGFloat radius = 20.0;
  CGPoint center = CGPointZero;
  CGFloat start_angle = 0.0;
  CGFloat end_angle = 0.0;
  XCTAssertTrue(SvgArcToCgArc(start_point, end_point, false, true,
                              &radius, &center, &start_angle, &end_angle));
  XCTAssertEqualWithAccuracy(center.x, 40.0, kTolerance);
  XCTAssertEqualWithAccuracy(center.y, 40.0, kTolerance);
  XCTAssertTrue(AreAnglesClose(start_angle, -kPi / 2, kTolerance));
  XCTAssertTrue(AreAnglesClose(end_angle, kPi / 2, kTolerance));
}

- (void)testSvgArcToCgArc_ErrorSamePoint {
  CGPoint start_point = CGPointMake(40.0, 60.0);
  CGPoint end_point = CGPointMake(40.0, 60.0);
  CGFloat radius = 20.0;
  CGPoint center = CGPointZero;
  CGFloat start_angle = 0.0;
  CGFloat end_angle = 0.0;
  XCTAssertFalse(SvgArcToCgArc(start_point, end_point, false, true,
                               &radius, &center, &start_angle, &end_angle));
}

- (void)testSvgArcToCgArc_ErrorNegativeRadius {
  CGPoint start_point = CGPointMake(20.0, 60.0);
  CGPoint end_point = CGPointMake(40.0, 40.0);
  CGFloat radius = -20.0;
  CGPoint center = CGPointZero;
  CGFloat start_angle = 0.0;
  CGFloat end_angle = 0.0;
  XCTAssertFalse(SvgArcToCgArc(start_point, end_point, false, true,
                               &radius, &center, &start_angle, &end_angle));
}

- (void)testAssertAngleEqualWithAccuracy_EdgeCaseFalse {
  XCTAssertFalse(AreAnglesClose(kPi, kPi + 1.01f * kTolerance, kTolerance));
}

- (void)testAssertAngleEqualWithAccuracy_EdgeCaseTrue {
  XCTAssertTrue(AreAnglesClose(kPi, kPi + 0.99f * kTolerance, kTolerance));
}

- (void)testAssertAngleEqualWithAccuracy_Minus2pi {
  XCTAssertTrue(AreAnglesClose(-kPi, kPi, kTolerance));
}

- (void)testAssertAngleEqualWithAccuracy_MultipleOf2pi {
  XCTAssertTrue(AreAnglesClose(5 * kPi, kPi, kTolerance));
}

- (void)testAssertAngleEqualWithAccuracy_NormalTest {
  XCTAssertTrue(AreAnglesClose(kPi / 2, kPi / 2, kTolerance));
}

- (void)testAssertAngleEqualWithAccuracy_False {
  XCTAssertFalse(AreAnglesClose(kPi / 2, kPi, kTolerance));
}

- (void)testCGAffineTransformToNormalizeRect {
  CGRect rect = CGRectMake(30, 50, 120, 390);
  CGAffineTransform transform = CGAffineTransformToNormalizeRect(rect);
  XCTAssertEqual(transform.a, 120);
  XCTAssertEqual(transform.b, 0);
  XCTAssertEqual(transform.c, 0);
  XCTAssertEqual(transform.d, 390);
  XCTAssertEqual(transform.tx, 30);
  XCTAssertEqual(transform.ty, 50);
}

- (void)testCGAffineTransformForPreserveAspectRatio_Nonuniform {
  CGRect target_viewport = CGRectMake(0, 0, 100, 100);
  CGRect view_box = CGRectMake(0, 0, 20, 10);
  PreserveAspectRatio r = PreserveAspectRatio::default_value();
  r.no_alignment = true;
  CGAffineTransform t =
      CGAffineTransformForPreserveAspectRatio(r, view_box, target_viewport);
  AssertCGAffineTransformEqual(t, CGAffineTransformMakeScale(5, 10));
}

- (void)testCGAffineTransformForPreserveAspectRatio_Meet_LandscapeViewBox {
  CGRect target_viewport = CGRectMake(0, 0, 100, 100);
  // The object is uniformly scaled to 100 x 50.
  CGRect view_box = CGRectMake(0, 0, 20, 10);
  PreserveAspectRatio r = PreserveAspectRatio::default_value();
  r.meet_or_slice = PreserveAspectRatio::kMeet;

  r.x_alignment = PreserveAspectRatio::kMin;
  r.y_alignment = PreserveAspectRatio::kMin;
  CGAffineTransform t =
      CGAffineTransformForPreserveAspectRatio(r, view_box, target_viewport);
  AssertCGAffineTransformEqual(t, UniformScaleThenTranslate(5, 0, 0));

  r.x_alignment = PreserveAspectRatio::kMid;
  r.y_alignment = PreserveAspectRatio::kMid;
  t = CGAffineTransformForPreserveAspectRatio(r, view_box, target_viewport);
  AssertCGAffineTransformEqual(t, UniformScaleThenTranslate(5, 0, 25));

  r.x_alignment = PreserveAspectRatio::kMax;
  r.y_alignment = PreserveAspectRatio::kMax;
  t = CGAffineTransformForPreserveAspectRatio(r, view_box, target_viewport);
  AssertCGAffineTransformEqual(t, UniformScaleThenTranslate(5, 0, 50));
}

- (void)testCGAffineTransformForPreserveAspectRatio_Meet_PortraitViewBox {
  CGRect target_viewport = CGRectMake(0, 0, 100, 100);
  // The object is uniformly scaled to 50 x 100.
  CGRect view_box = CGRectMake(0, 0, 10, 20);
  PreserveAspectRatio r = PreserveAspectRatio::default_value();
  r.meet_or_slice = PreserveAspectRatio::kMeet;

  r.x_alignment = PreserveAspectRatio::kMin;
  r.y_alignment = PreserveAspectRatio::kMin;
  CGAffineTransform t =
      CGAffineTransformForPreserveAspectRatio(r, view_box, target_viewport);
  AssertCGAffineTransformEqual(t, UniformScaleThenTranslate(5, 0, 0));

  r.x_alignment = PreserveAspectRatio::kMid;
  r.y_alignment = PreserveAspectRatio::kMid;
  t = CGAffineTransformForPreserveAspectRatio(r, view_box, target_viewport);
  AssertCGAffineTransformEqual(t, UniformScaleThenTranslate(5, 25, 0));

  r.x_alignment = PreserveAspectRatio::kMax;
  r.y_alignment = PreserveAspectRatio::kMax;
  t = CGAffineTransformForPreserveAspectRatio(r, view_box, target_viewport);
  AssertCGAffineTransformEqual(t, UniformScaleThenTranslate(5, 50, 0));
}

- (void)testCGAffineTransformForPreserveAspectRatio_Slice_LandscapeViewBox {
  CGRect target_viewport = CGRectMake(0, 0, 100, 100);
  // The object is uniformly scaled to 200 x 100 (and cliped).
  CGRect view_box = CGRectMake(0, 0, 20, 10);
  PreserveAspectRatio r = PreserveAspectRatio::default_value();
  r.meet_or_slice = PreserveAspectRatio::kSlice;

  r.x_alignment = PreserveAspectRatio::kMin;
  r.y_alignment = PreserveAspectRatio::kMin;
  CGAffineTransform t =
      CGAffineTransformForPreserveAspectRatio(r, view_box, target_viewport);
  AssertCGAffineTransformEqual(t, UniformScaleThenTranslate(10, 0, 0));

  r.x_alignment = PreserveAspectRatio::kMid;
  r.y_alignment = PreserveAspectRatio::kMid;
  t = CGAffineTransformForPreserveAspectRatio(r, view_box, target_viewport);
  AssertCGAffineTransformEqual(t, UniformScaleThenTranslate(10, -50, 0));

  r.x_alignment = PreserveAspectRatio::kMax;
  r.y_alignment = PreserveAspectRatio::kMax;
  t = CGAffineTransformForPreserveAspectRatio(r, view_box, target_viewport);
  AssertCGAffineTransformEqual(t, UniformScaleThenTranslate(10, -100, 0));
}

- (void)testCGAffineTransformForPreserveAspectRatio_Slice_PortrailViewBox {
  CGRect target_viewport = CGRectMake(0, 0, 100, 100);
  // The object is uniformly scaled to 100 x 200 (and cliped)
  CGRect view_box = CGRectMake(0, 0, 10, 20);
  PreserveAspectRatio r = PreserveAspectRatio::default_value();
  r.meet_or_slice = PreserveAspectRatio::kSlice;

  r.x_alignment = PreserveAspectRatio::kMin;
  r.y_alignment = PreserveAspectRatio::kMin;
  CGAffineTransform t =
      CGAffineTransformForPreserveAspectRatio(r, view_box, target_viewport);
  AssertCGAffineTransformEqual(t, UniformScaleThenTranslate(10, 0, 0));

  r.x_alignment = PreserveAspectRatio::kMid;
  r.y_alignment = PreserveAspectRatio::kMid;
  t = CGAffineTransformForPreserveAspectRatio(r, view_box, target_viewport);
  AssertCGAffineTransformEqual(t, UniformScaleThenTranslate(10, 0, -50));

  r.x_alignment = PreserveAspectRatio::kMax;
  r.y_alignment = PreserveAspectRatio::kMax;
  t = CGAffineTransformForPreserveAspectRatio(r, view_box, target_viewport);
  AssertCGAffineTransformEqual(t, UniformScaleThenTranslate(10, 0, -100));
}

- (void)testEvaluateLength_NoUnit {
  Length length(100, Length::kUnitNone);
  CGFloat value = EvaluateLength(length);
  XCTAssertEqualWithAccuracy(value, 100, kTolerance);
}

- (void)testEvaluateLength_Percentage {
  Length length(100, Length::kUnitPercent);
  CGFloat value = EvaluateLength(length);
  XCTAssertEqualWithAccuracy(value, 1, kTolerance);
}

@end
