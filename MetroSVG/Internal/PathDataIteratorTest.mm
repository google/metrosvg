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

#include "MetroSVG/Internal/PathDataIterator.h"
#include "MetroSVG/Internal/StringPiece.h"

using namespace metrosvg::internal;

@interface PathDataIteratorTest : XCTestCase
@end

@implementation PathDataIteratorTest

- (void)testMove {
  PathDataIterator iter("M38.967,20.762", kPathDataFormatPath, false);

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeMoveTo);
  XCTAssertEqualWithAccuracy(iter.point().x, 38.967, 0.001);
  XCTAssertEqualWithAccuracy(iter.point().y, 20.762, 0.001);

  XCTAssertFalse(iter.Next());
}

- (void)testRelativeHorizontalLine {
  PathDataIterator iter("M10,10h50", kPathDataFormatPath, false);

  XCTAssertTrue(iter.Next());

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeHorizontalLineTo);
  XCTAssertEqualWithAccuracy(iter.point().x, 60., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 10., 0.0001);

  XCTAssertFalse(iter.Next());
}

- (void)testAbsoluteHorizontalLine {
  PathDataIterator iter("M10,10H50", kPathDataFormatPath, false);

  XCTAssertTrue(iter.Next());

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeHorizontalLineTo);
  XCTAssertEqualWithAccuracy(iter.point().x, 50., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 10., 0.0001);

  XCTAssertFalse(iter.Next());
}

- (void)testRelativeVerticalLine {
  PathDataIterator iter("M10,10v50", kPathDataFormatPath, false);

  XCTAssertTrue(iter.Next());

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeVerticalLineTo);
  XCTAssertEqualWithAccuracy(iter.point().x, 10., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 60., 0.0001);

  XCTAssertFalse(iter.Next());
}

- (void)testAbsoluteVerticalLine {
  PathDataIterator iter("M10,10V50", kPathDataFormatPath, false);

  XCTAssertTrue(iter.Next());

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeVerticalLineTo);
  XCTAssertEqualWithAccuracy(iter.point().x, 10., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 50., 0.0001);

  XCTAssertFalse(iter.Next());
}

- (void)testRelativeGeneralLine {
  PathDataIterator iter("M10,10l50,50", kPathDataFormatPath, false);

  XCTAssertTrue(iter.Next());

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeLineTo);
  XCTAssertEqualWithAccuracy(iter.point().x, 60., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 60., 0.0001);

  XCTAssertFalse(iter.Next());
}

- (void)testAbsoluteGeneralLine {
  PathDataIterator iter("M10,10L50,50", kPathDataFormatPath, false);

  XCTAssertTrue(iter.Next());

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeLineTo);
  XCTAssertEqualWithAccuracy(iter.point().x, 50., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 50., 0.0001);

  XCTAssertFalse(iter.Next());
}

- (void)testRelativeCubicBezier {
  PathDataIterator iter("M10,10c10,30,30,10,30,30", kPathDataFormatPath, false);

  XCTAssertTrue(iter.Next());

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeCubicBezier);
  XCTAssertEqualWithAccuracy(iter.point().x, 40., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 40., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().x, 20., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().y, 40., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point2().x, 40., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point2().y, 20., 0.0001);

  XCTAssertFalse(iter.Next());
}

- (void)testAbsoluteCubicBezier {
  PathDataIterator iter("M10,10C10,30,30,10,30,30", kPathDataFormatPath, false);

  XCTAssertTrue(iter.Next());

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeCubicBezier);
  XCTAssertEqualWithAccuracy(iter.point().x, 30., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 30., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().x, 10., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().y, 30., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point2().x, 30., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point2().y, 10., 0.0001);

  XCTAssertFalse(iter.Next());
}

- (void)testRelativeShorthandCubicBezier {
  PathDataIterator iter("M10,10s10 10 10 0s10-10 10 0",
                        kPathDataFormatPath, false);

  XCTAssertTrue(iter.Next());

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeShorthandCubicBezier);
  XCTAssertEqualWithAccuracy(iter.point().x, 20., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 10., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().x, 10., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().y, 10., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point2().x, 20., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point2().y, 20., 0.0001);

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeShorthandCubicBezier);
  XCTAssertEqualWithAccuracy(iter.point().x, 30., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 10., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().x, 20., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().y, 0., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point2().x, 30., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point2().y, 0., 0.0001);

  XCTAssertFalse(iter.Next());
}

- (void)testAbsoluteShorthandCubicBezier {
  PathDataIterator iter("M10,10S20 20 20 10S30 0 30 10",
                        kPathDataFormatPath, false);

  XCTAssertTrue(iter.Next());

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeShorthandCubicBezier);
  XCTAssertEqualWithAccuracy(iter.point().x, 20., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 10., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().x, 10., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().y, 10., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point2().x, 20., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point2().y, 20., 0.0001);

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeShorthandCubicBezier);
  XCTAssertEqualWithAccuracy(iter.point().x, 30., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 10., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().x, 20., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().y, 0., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point2().x, 30., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point2().y, 0., 0.0001);

  XCTAssertFalse(iter.Next());
}

- (void)testRelativeQuadBezier {
  PathDataIterator iter("M10,10q10,30,30,30", kPathDataFormatPath, false);

  XCTAssertTrue(iter.Next());

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeQuadBezier);
  XCTAssertEqualWithAccuracy(iter.point().x, 40., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 40., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().x, 20., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().y, 40., 0.0001);

  XCTAssertFalse(iter.Next());
}

- (void)testAbsoluteQuadBezier {
  PathDataIterator iter("M10,10Q10,30,30,30", kPathDataFormatPath, false);

  XCTAssertTrue(iter.Next());

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeQuadBezier);
  XCTAssertEqualWithAccuracy(iter.point().x, 30., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 30., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().x, 10., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().y, 30., 0.0001);

  XCTAssertFalse(iter.Next());
}

- (void)testRelativeShorthandQuadBezier {
  PathDataIterator iter("M10 10t10 10t20 20", kPathDataFormatPath, false);

  XCTAssertTrue(iter.Next());

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeShorthandQuadBezier);
  XCTAssertEqualWithAccuracy(iter.point().x, 20., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 20., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().x, 10., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().y, 10., 0.0001);

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeShorthandQuadBezier);
  XCTAssertEqualWithAccuracy(iter.point().x, 40., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 40., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().x, 30., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().y, 30., 0.0001);

  XCTAssertFalse(iter.Next());
}

- (void)testAbsoluteShorthandQuadBezier {
  PathDataIterator iter("M10 10T20 20T40 40", kPathDataFormatPath, false);

  XCTAssertTrue(iter.Next());

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeShorthandQuadBezier);
  XCTAssertEqualWithAccuracy(iter.point().x, 20., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 20., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().x, 10., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().y, 10., 0.0001);

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeShorthandQuadBezier);
  XCTAssertEqualWithAccuracy(iter.point().x, 40., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 40., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().x, 30., 0.0001);
  XCTAssertEqualWithAccuracy(iter.control_point1().y, 30., 0.0001);

  XCTAssertFalse(iter.Next());
}

- (void)testRelativeEllipticalArc {
  PathDataIterator iter("m 150 100 a 50 40 0 1 0 25 -70",
                        kPathDataFormatPath, false);

  XCTAssertTrue(iter.Next());

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeEllipticalArc);
  XCTAssertEqualWithAccuracy(iter.arc_radius_x(), 50., 0.0001);
  XCTAssertEqualWithAccuracy(iter.arc_radius_y(), 40., 0.0001);
  XCTAssertEqualWithAccuracy(iter.rotation(), 0., 0.0001);
  XCTAssertEqualWithAccuracy(iter.large_arc(), 1., 0.0001);
  XCTAssertEqualWithAccuracy(iter.sweep(), 0., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().x, 175., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 30., 0.0001);

  XCTAssertFalse(iter.Next());
}

- (void)testRelativeEllipticalArc_ConcatenatedParameters {
  PathDataIterator iter("m150,100a50,40,0,1025-70",
                        kPathDataFormatPath, false);

  XCTAssertTrue(iter.Next());

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeEllipticalArc);
  XCTAssertEqualWithAccuracy(iter.arc_radius_x(), 50., 0.0001);
  XCTAssertEqualWithAccuracy(iter.arc_radius_y(), 40., 0.0001);
  XCTAssertEqualWithAccuracy(iter.rotation(), 0., 0.0001);
  XCTAssertEqualWithAccuracy(iter.large_arc(), 1., 0.0001);
  XCTAssertEqualWithAccuracy(iter.sweep(), 0., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().x, 175., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 30., 0.0001);

  XCTAssertFalse(iter.Next());
}

- (void)testAbsoluteEllipticalArc {
  PathDataIterator iter("M 215 190 A 40 200 10 0 0 265 190",
                        kPathDataFormatPath, false);

  XCTAssertTrue(iter.Next());

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeEllipticalArc);
  XCTAssertEqualWithAccuracy(iter.arc_radius_x(), 40., 0.0001);
  XCTAssertEqualWithAccuracy(iter.arc_radius_y(), 200., 0.0001);
  XCTAssertEqualWithAccuracy(iter.rotation(), 10., 0.0001);
  XCTAssertEqualWithAccuracy(iter.large_arc(), 0., 0.0001);
  XCTAssertEqualWithAccuracy(iter.sweep(), 0., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().x, 265., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 190., 0.0001);

  XCTAssertFalse(iter.Next());
}

- (void)testPolygon_Commas {
  PathDataIterator iter("10,10,20,20", kPathDataFormatPoints, true);

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeMoveTo);
  XCTAssertEqualWithAccuracy(iter.point().x, 10., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 10., 0.0001);

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeLineTo);
  XCTAssertEqualWithAccuracy(iter.point().x, 20., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 20., 0.0001);

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeClosePath);

  XCTAssertFalse(iter.Next());
}

- (void)testPath_Commas {
  PathDataIterator iter("M10,50 L35,150,60,50", kPathDataFormatPath, true);

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeMoveTo);
  XCTAssertEqualWithAccuracy(iter.point().x, 10., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 50., 0.0001);

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeLineTo);
  XCTAssertEqualWithAccuracy(iter.point().x, 35., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 150., 0.0001);

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeLineTo);
  XCTAssertEqualWithAccuracy(iter.point().x, 60., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 50., 0.0001);

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeClosePath);

  XCTAssertFalse(iter.Next());
}

- (void)testPath_MultipleSubpaths {
  PathDataIterator iter("M10 10 l0 20 z l 20 0", kPathDataFormatPath, false);

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeMoveTo);
  XCTAssertEqualWithAccuracy(iter.point().x, 10., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 10., 0.0001);

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeLineTo);
  XCTAssertEqualWithAccuracy(iter.point().x, 10., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 30., 0.0001);

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeClosePath);

  XCTAssertTrue(iter.Next());
  // ClosePath resets the current point to the last path's starting point.
  XCTAssertEqual(iter.command_type(), kPathCommandTypeLineTo);
  XCTAssertEqualWithAccuracy(iter.point().x, 30., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 10., 0.0001);

  XCTAssertFalse(iter.Next());
}

- (void)testPolygon_Spaces {
  PathDataIterator iter("10 10 20 20", kPathDataFormatPoints, false);

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeMoveTo);
  XCTAssertEqualWithAccuracy(iter.point().x, 10., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 10., 0.0001);

  XCTAssertTrue(iter.Next());
  XCTAssertEqual(iter.command_type(), kPathCommandTypeLineTo);
  XCTAssertEqualWithAccuracy(iter.point().x, 20., 0.0001);
  XCTAssertEqualWithAccuracy(iter.point().y, 20., 0.0001);

  XCTAssertFalse(iter.Next());
}

@end
