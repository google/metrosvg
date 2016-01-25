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

#include <cmath>

#include "MetroSVG/Internal/StringPiece.h"
#include "MetroSVG/Internal/TransformIterator.h"
#include "MetroSVG/Internal/Utils.h"

using namespace metrosvg::internal;

static const CGFloat kTolerance = 0.0001f;

@interface TransformIteratorTest : XCTestCase
@end

@implementation TransformIteratorTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testMatrix {
  TransformIterator iter(new StringPiece("matrix(10,20,30,40,50,60)"));

  XCTAssertTrue(iter.Next());
  const CGAffineTransform &transform = iter.transform();
  XCTAssertEqualWithAccuracy(transform.a, 10., kTolerance);
  XCTAssertEqualWithAccuracy(transform.b, 20., kTolerance);
  XCTAssertEqualWithAccuracy(transform.c, 30., kTolerance);
  XCTAssertEqualWithAccuracy(transform.d, 40., kTolerance);
  XCTAssertEqualWithAccuracy(transform.tx, 50., kTolerance);
  XCTAssertEqualWithAccuracy(transform.ty, 60., kTolerance);

  XCTAssertFalse(iter.Next());
}

- (void)testMatrix_FailureTooFewArguments {
  StringPiece sp("matrix(1 2 3 4 5)");
  size_t original_length = sp.length();
  TransformIterator iter(&sp);

  XCTAssertFalse(iter.Next());
  XCTAssertEqual(sp.length(), original_length);
}

- (void)testTranslate_Success {
  TransformIterator iter(new StringPiece("translate(10,20)"));

  XCTAssertTrue(iter.Next());
  const CGAffineTransform &transform = iter.transform();
  XCTAssertEqualWithAccuracy(transform.a, 1., kTolerance);
  XCTAssertEqualWithAccuracy(transform.b, 0., kTolerance);
  XCTAssertEqualWithAccuracy(transform.c, 0., kTolerance);
  XCTAssertEqualWithAccuracy(transform.d, 1., kTolerance);
  XCTAssertEqualWithAccuracy(transform.tx, 10., kTolerance);
  XCTAssertEqualWithAccuracy(transform.ty, 20., kTolerance);

  XCTAssertFalse(iter.Next());
}

- (void)testTranslate_SuccessOneValue {
  TransformIterator iter(new StringPiece("translate(10)"));

  XCTAssertTrue(iter.Next());
  const CGAffineTransform &transform = iter.transform();
  XCTAssertEqualWithAccuracy(transform.a, 1., kTolerance);
  XCTAssertEqualWithAccuracy(transform.b, 0., kTolerance);
  XCTAssertEqualWithAccuracy(transform.c, 0., kTolerance);
  XCTAssertEqualWithAccuracy(transform.d, 1., kTolerance);
  XCTAssertEqualWithAccuracy(transform.tx, 10., kTolerance);
  XCTAssertEqualWithAccuracy(transform.ty, 0., kTolerance);

  XCTAssertFalse(iter.Next());
}

- (void)testTranslate_FailureNoParens {
  StringPiece sp("translate 10 10");
  size_t original_length = sp.length();
  TransformIterator iter(&sp);

  XCTAssertFalse(iter.Next());
  XCTAssertEqual(sp.length(), original_length);
}

- (void)testTranslate_FailureTooManyArguments {
  StringPiece sp("translate(10, 30, 40, 70)");
  size_t original_length = sp.length();
  TransformIterator iter(&sp);

  XCTAssertFalse(iter.Next());
  XCTAssertEqual(sp.length(), original_length);
}

- (void)testScale_Success {
  TransformIterator iter(new StringPiece("scale(10,20)"));

  XCTAssertTrue(iter.Next());
  const CGAffineTransform &transform = iter.transform();
  XCTAssertEqualWithAccuracy(transform.a, 10., kTolerance);
  XCTAssertEqualWithAccuracy(transform.b, 0., kTolerance);
  XCTAssertEqualWithAccuracy(transform.c, 0., kTolerance);
  XCTAssertEqualWithAccuracy(transform.d, 20., kTolerance);
  XCTAssertEqualWithAccuracy(transform.tx, 0., kTolerance);
  XCTAssertEqualWithAccuracy(transform.ty, 0., kTolerance);

  XCTAssertFalse(iter.Next());
}

- (void)testScale_SuccessOneValue {
  TransformIterator iter(new StringPiece("scale(15 )"));

  XCTAssertTrue(iter.Next());
  const CGAffineTransform &transform = iter.transform();
  XCTAssertEqualWithAccuracy(transform.a, 15., kTolerance);
  XCTAssertEqualWithAccuracy(transform.b, 0., kTolerance);
  XCTAssertEqualWithAccuracy(transform.c, 0., kTolerance);
  XCTAssertEqualWithAccuracy(transform.d, 15., kTolerance);
  XCTAssertEqualWithAccuracy(transform.tx, 0., kTolerance);
  XCTAssertEqualWithAccuracy(transform.ty, 0., kTolerance);

  XCTAssertFalse(iter.Next());
}

- (void)testScale_FailureMismatchedParens {
  StringPiece sp("scale(10 40");
  size_t original_length = sp.length();
  TransformIterator iter(&sp);

  XCTAssertFalse(iter.Next());
  XCTAssertEqual(sp.length(), original_length);
}

- (void)testScale_FailureTooManyFloats {
  StringPiece sp("scale(10 40 60");
  size_t original_length = sp.length();
  TransformIterator iter(&sp);

  XCTAssertFalse(iter.Next());
  XCTAssertEqual(sp.length(), original_length);
}

- (void)testRotate_SuccessNoCenter {
  const CGFloat OneOverRoot2 = 1.f / std::sqrt(2.f);
  TransformIterator iter(new StringPiece("rotate(45)"));

  XCTAssertTrue(iter.Next());
  const CGAffineTransform &transform = iter.transform();
  XCTAssertEqualWithAccuracy(transform.a, OneOverRoot2, kTolerance);
  XCTAssertEqualWithAccuracy(transform.b, OneOverRoot2, kTolerance);
  XCTAssertEqualWithAccuracy(transform.c, -OneOverRoot2, kTolerance);
  XCTAssertEqualWithAccuracy(transform.d, OneOverRoot2, kTolerance);
  XCTAssertEqualWithAccuracy(transform.tx, 0., kTolerance);
  XCTAssertEqualWithAccuracy(transform.ty, 0., kTolerance);

  XCTAssertFalse(iter.Next());
}

- (void)testRotate_SuccessCenter {
  const CGFloat Root2 = std::sqrt(2.f);
  const CGFloat OneOverRoot2 = 1.f / std::sqrt(2.f);
  TransformIterator iter(new StringPiece("rotate(45,1 1)"));

  XCTAssertTrue(iter.Next());
  const CGAffineTransform &transform = iter.transform();
  XCTAssertEqualWithAccuracy(transform.a, OneOverRoot2, kTolerance);
  XCTAssertEqualWithAccuracy(transform.b, OneOverRoot2, kTolerance);
  XCTAssertEqualWithAccuracy(transform.c, -OneOverRoot2, kTolerance);
  XCTAssertEqualWithAccuracy(transform.d, OneOverRoot2, kTolerance);
  XCTAssertEqualWithAccuracy(transform.tx, -1., kTolerance);
  XCTAssertEqualWithAccuracy(transform.ty, Root2 - 1.0, kTolerance);

  XCTAssertFalse(iter.Next());
}

- (void)testRotate_FailureTooFewArguments {
  StringPiece sp("rotate()");
  size_t original_length = sp.length();
  TransformIterator iter(&sp);

  XCTAssertFalse(iter.Next());
  XCTAssertEqual(sp.length(), original_length);
}

- (void)testRotate_FailureExactlyTwoArguments {
  StringPiece sp("rotate(45 200.)");
  size_t original_length = sp.length();
  TransformIterator iter(&sp);

  XCTAssertFalse(iter.Next());
  XCTAssertEqual(sp.length(), original_length);
}

- (void)testSkewX {
  const CGFloat tan45 = std::tan(ToRadians(45.f));
  TransformIterator iter(new StringPiece("skewX(45)"));

  XCTAssertTrue(iter.Next());
  const CGAffineTransform &transform = iter.transform();
  XCTAssertEqualWithAccuracy(transform.a, 1.0, kTolerance);
  XCTAssertEqualWithAccuracy(transform.b, 0.0, kTolerance);
  XCTAssertEqualWithAccuracy(transform.c, tan45, kTolerance);
  XCTAssertEqualWithAccuracy(transform.d, 1.0, kTolerance);
  XCTAssertEqualWithAccuracy(transform.tx, 0., kTolerance);
  XCTAssertEqualWithAccuracy(transform.ty, 0., kTolerance);

  XCTAssertFalse(iter.Next());
}

- (void)testSkewX_FailureTooFewArguments {
  StringPiece sp("skewX()");
  size_t original_length = sp.length();
  TransformIterator iter(&sp);

  XCTAssertFalse(iter.Next());
  XCTAssertEqual(sp.length(), original_length);
}

- (void)testSkewY {
  const CGFloat tan45 = std::tan(ToRadians(45.f));
  TransformIterator iter(new StringPiece("skewY(45)"));

  XCTAssertTrue(iter.Next());
  const CGAffineTransform &transform = iter.transform();
  XCTAssertEqualWithAccuracy(transform.a, 1.0, kTolerance);
  XCTAssertEqualWithAccuracy(transform.b, tan45, kTolerance);
  XCTAssertEqualWithAccuracy(transform.c, 0.0, kTolerance);
  XCTAssertEqualWithAccuracy(transform.d, 1.0, kTolerance);
  XCTAssertEqualWithAccuracy(transform.tx, 0., kTolerance);
  XCTAssertEqualWithAccuracy(transform.ty, 0., kTolerance);

  XCTAssertFalse(iter.Next());
}

- (void)testCompositeTransform_SuccessNoDelimiter {
  // The BNF for values for the transform attribute doesn't allow an empty
  // string as a delimeter.
  // http://www.w3.org/TR/SVG/coords.html#TransformAttribute
  // However, the test suite that W3C provides and other major implementations
  // accepts an empty string as a delemeter. We follow this convention.
  TransformIterator iter(new StringPiece("scale(15)translate(10)scale(15)"));

  XCTAssertTrue(iter.Next());
  XCTAssertEqualWithAccuracy(iter.transform().a, 15., kTolerance);

  XCTAssertTrue(iter.Next());
  XCTAssertEqualWithAccuracy(iter.transform().tx, 10., kTolerance);

  XCTAssertTrue(iter.Next());
  XCTAssertEqualWithAccuracy(iter.transform().a, 15., kTolerance);

  XCTAssertFalse(iter.Next());
}

- (void)testCompositeTransform_SuccessNoComma {
  TransformIterator iter(new StringPiece(
      "scale(15) translate(10) \t\r scale(15)"));

  XCTAssertTrue(iter.Next());
  XCTAssertEqualWithAccuracy(iter.transform().a, 15., kTolerance);

  XCTAssertTrue(iter.Next());
  XCTAssertEqualWithAccuracy(iter.transform().tx, 10., kTolerance);

  XCTAssertTrue(iter.Next());
  XCTAssertEqualWithAccuracy(iter.transform().a, 15., kTolerance);

  XCTAssertFalse(iter.Next());
}

- (void)testCompositeTransform_SuccessCommas {
  TransformIterator iter(new StringPiece(
      "scale(15),translate(10) \t,,\r ,scale(15)"));

  XCTAssertTrue(iter.Next());
  XCTAssertEqualWithAccuracy(iter.transform().a, 15., kTolerance);

  XCTAssertTrue(iter.Next());
  XCTAssertEqualWithAccuracy(iter.transform().tx, 10., kTolerance);

  XCTAssertTrue(iter.Next());
  XCTAssertEqualWithAccuracy(iter.transform().a, 15., kTolerance);

  XCTAssertFalse(iter.Next());
}

- (void)testCompositeTransform_FailureIllegalDelemiter {
  TransformIterator iter(new StringPiece("translate(10)|scale(15)"));

  XCTAssertTrue(iter.Next());
  XCTAssertFalse(iter.Next());
}

- (void)testSkewY_FailureTooFewArguments {
  StringPiece sp("skewY(    )");
  size_t original_length = sp.length();
  TransformIterator iter(&sp);

  XCTAssertFalse(iter.Next());
  XCTAssertEqual(sp.length(), original_length);
}

- (void)testEmpty_Failure {
  StringPiece sp("");
  size_t original_length = sp.length();
  TransformIterator iter(&sp);

  XCTAssertFalse(iter.Next());
  XCTAssertEqual(sp.length(), original_length);
}

- (void)testUnknownTransform_Failure {
  StringPiece sp("Lorentz(50 60)");
  size_t original_length = sp.length();
  TransformIterator iter(&sp);

  XCTAssertFalse(iter.Next());
  XCTAssertEqual(sp.length(), original_length);
}

@end
