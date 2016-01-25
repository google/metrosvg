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

#include "MetroSVG/Internal/BasicTypes.h"
#include "MetroSVG/Internal/BasicValueParsers.h"
#include "MetroSVG/Internal/StringPiece.h"

using namespace metrosvg::internal;

static const CGFloat kTolerance = 0.001f;

@interface BasicValueParsersTest : XCTestCase
@end

@implementation BasicValueParsersTest

- (void)testConsumeSign_Negative {
  StringPiece s("-55");
  bool was_negative = ConsumeSign(&s);
  XCTAssertTrue(was_negative);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeSign_Positive {
  StringPiece s("+55");
  size_t original_length = s.length();
  bool was_negative = ConsumeSign(&s);
  XCTAssertFalse(was_negative);
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumeSign_Failure {
  StringPiece s("bill");
  size_t original_length = s.length();
  bool was_negative = ConsumeSign(&s);
  XCTAssertFalse(was_negative);
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumeDecimalInt_Success {
  StringPiece s("592@@");
  int n;
  XCTAssertTrue(ConsumeDecimalInt(&s, &n));
  XCTAssertEqual(n, 592);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeDecimalInt_Failure {
  StringPiece s("@@592");
  int n;
  size_t original_length = s.length();
  XCTAssertFalse(ConsumeDecimalInt(&s, &n));
  XCTAssertEqual(original_length, s.length());
}

- (void)testConsumeDecimalIntPercent_Success {
  StringPiece s("592%@@");
  int n;
  XCTAssertTrue(ConsumeDecimalIntPercent(&s, &n));
  XCTAssertEqual(n, 592);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeDecimalIntPercent_FailureNoSynbol {
  StringPiece s("592@@");
  int n;
  size_t original_length = s.length();
  XCTAssertFalse(ConsumeDecimalIntPercent(&s, &n));
  XCTAssertEqual(original_length, s.length());
}

- (void)testConsumeDecimalIntPercent_FailureSynbolOnly {
  StringPiece s("%@@");
  int n;
  size_t original_length = s.length();
  XCTAssertFalse(ConsumeDecimalIntPercent(&s, &n));
  XCTAssertEqual(original_length, s.length());
}

- (void)testConsumeHexInt_Success {
  StringPiece s("c8a@@");
  int n;
  XCTAssertTrue(ConsumeHexInt(&s, 3, &n));
  XCTAssertEqual(n, 3210);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeHexInt_SuccessPieceLongerThanWidth {
  StringPiece s("c86ba@@");
  int n;
  XCTAssertTrue(ConsumeHexInt(&s, 4, &n));
  XCTAssertEqual(n, 51307);
  XCTAssertEqual(s.length(), 3U);
}

- (void)testConsumeHexInt_SuccessWidthNotSpecified {
  StringPiece s("c8a@@");
  int n;
  XCTAssertTrue(ConsumeHexInt(&s, -1, &n));
  XCTAssertEqual(n, 3210);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeHexInt_FailurePieceShorterThanWidth {
  StringPiece s("c8a");
  size_t original_length = s.length();
  int n;
  XCTAssertFalse(ConsumeHexInt(&s, 4, &n));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumeHexInt_FailureHexDigitsShorterThanWidth {
  StringPiece s("c8a@@");
  size_t original_length = s.length();
  int n;
  XCTAssertFalse(ConsumeHexInt(&s, 4, &n));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumeHexInt_FailureWidthNotSpecified {
  StringPiece s("@@");
  size_t original_length = s.length();
  int n;
  XCTAssertFalse(ConsumeHexInt(&s, -1, &n));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumeFloat_Success {
  StringPiece s("123.456@@");
  CGFloat f;
  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, 123.456, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeFloat_SuccessNegative {
  StringPiece s("-123.456@@");
  CGFloat f;
  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, -123.456, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeFloat_SuccessNoFraction {
  StringPiece s("123@@");
  CGFloat f;
  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, 123, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeFloat_SuccessNoFractionNegative {
  StringPiece s("-123@@");
  CGFloat f;
  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, -123, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeFloat_SuccessNoFractionDecimal {
  StringPiece s("123.@@");
  CGFloat f;
  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, 123, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeFloat_SuccessNoInteger {
  StringPiece s(".123@@");
  CGFloat f;
  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, 0.123, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeFloat_SuccessNoIntegerNegative {
  StringPiece s("-.123@@");
  CGFloat f;
  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, -0.123, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeFloat_SuccessIntegerPlusExponent {
  StringPiece s("123e3@@");
  CGFloat f;
  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, 123000, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeFloat_SuccessIntegerNegativeExponent {
  StringPiece s("123e-3@@");
  CGFloat f;
  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, .123, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeFloat_SuccessNegativeIntegerNegativeExponent {
  StringPiece s("-123e-3@@");
  CGFloat f;
  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, -0.123, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeFloat_SuccessFractionPlusExponent {
  StringPiece s(".123e3@@");
  CGFloat f;
  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, 123, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeFloat_SuccessFractionMinusExponent {
  StringPiece s(".1e-1@@");
  CGFloat f;
  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, 0.01, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeFloat_SuccessShouldntSwallowE {
  StringPiece s("123e@@");
  CGFloat f;
  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, 123., kTolerance);
  XCTAssertEqual(s.length(), 3U);
}

- (void)testConsumeFloats_SuccessMultipleSpaces {
  StringPiece s("54.003 15.434 0.6");
  CGFloat f[3];
  XCTAssertTrue(ConsumeFloats(&s, 3, f));
  XCTAssertEqualWithAccuracy(f[0], 54.003, kTolerance);
  XCTAssertEqualWithAccuracy(f[1], 15.434, kTolerance);
  XCTAssertEqualWithAccuracy(f[2], 0.6, kTolerance);
  XCTAssertEqual(s.length(), 0U);
}

- (void)testConsumeFloats_SuccessMultipleCommas {
  StringPiece s("54.003,15.434,0.6");
  CGFloat f[3];
  XCTAssertTrue(ConsumeFloats(&s, 3, f));
  XCTAssertEqualWithAccuracy(f[0], 54.003, kTolerance);
  XCTAssertEqualWithAccuracy(f[1], 15.434, kTolerance);
  XCTAssertEqualWithAccuracy(f[2], 0.6, kTolerance);
  XCTAssertEqual(s.length(), 0U);
}

- (void)testConsumeFloat_SuccessMultipleCommands {
  StringPiece s("54.003,15.434c3.338,0,6.041-2.71,6.041-6.036c");
  size_t previous_length = s.length();
  CGFloat f;
  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, 54.003, kTolerance);
  XCTAssertEqual(previous_length, 6 + s.length());
  XCTAssertTrue(ConsumeNumberDelimiter(&s));
  previous_length = s.length();

  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, 15.434, kTolerance);
  XCTAssertEqual(previous_length, 6 + s.length());
  previous_length = s.length();

  XCTAssertTrue(ConsumeString(&s, "c", true));
  previous_length = s.length();

  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, 3.338, kTolerance);
  XCTAssertEqual(previous_length, 5 + s.length());
  XCTAssertTrue(ConsumeNumberDelimiter(&s));
  previous_length = s.length();

  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, 0, kTolerance);
  XCTAssertEqual(previous_length, 1 + s.length());
  XCTAssertTrue(ConsumeNumberDelimiter(&s));
  previous_length = s.length();

  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, 6.041, kTolerance);
  XCTAssertEqual(previous_length, 5 + s.length());
  previous_length = s.length();

  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, -2.71, kTolerance);
  XCTAssertEqual(previous_length, 5 + s.length());
  XCTAssertTrue(ConsumeNumberDelimiter(&s));
  previous_length = s.length();

  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, 6.041, kTolerance);
  XCTAssertEqual(previous_length, 5 + s.length());
  previous_length = s.length();

  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, -6.036, kTolerance);
  XCTAssertEqual(previous_length, 6 + s.length());
  previous_length = s.length();

  XCTAssertTrue(ConsumeString(&s, "c", true));
  XCTAssertEqual(s.length(), 0U);
}

- (void)testConsumeFloat_SuccessExtremelySmall {
  StringPiece s("1e-400@@");
  CGFloat f;
  // TODO: Is this the expected behavior?
  XCTAssertTrue(ConsumeFloat(&s, &f));
  XCTAssertEqualWithAccuracy(f, 0.0f, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeFloat_FailureNoNumber {
  StringPiece s("@@");
  size_t original_length = s.length();
  CGFloat f;
  XCTAssertFalse(ConsumeFloat(&s, &f));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumeFloat_FailureEmpty {
  StringPiece s("");
  size_t original_length = s.length();
  CGFloat f;
  XCTAssertFalse(ConsumeFloat(&s, &f));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumeFloat_FailureSignOnly {
  StringPiece s("-@@");
  size_t original_length = s.length();
  CGFloat f;
  XCTAssertFalse(ConsumeFloat(&s, &f));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumeFloat_FailureDecimalOnly {
  StringPiece s(".@@");
  size_t original_length = s.length();
  CGFloat f;
  XCTAssertFalse(ConsumeFloat(&s, &f));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumeFloat_FailureSignDecimalOnly {
  StringPiece s("-.@@");
  size_t original_length = s.length();
  CGFloat f;
  XCTAssertFalse(ConsumeFloat(&s, &f));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumeFloat_FailureSignDecimalEOnly {
  StringPiece s("-.e@@");
  size_t original_length = s.length();
  CGFloat f;
  XCTAssertFalse(ConsumeFloat(&s, &f));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumeFloat_FailureDecimalEOnly {
  StringPiece s(".e@@");
  size_t original_length = s.length();
  CGFloat f;
  XCTAssertFalse(ConsumeFloat(&s, &f));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumeFloat_FailureEOnly {
  StringPiece s("e@@");
  size_t original_length = s.length();
  CGFloat f;
  XCTAssertFalse(ConsumeFloat(&s, &f));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumeFloat_FailureNoBase {
  StringPiece s("e-4@@");
  size_t original_length = s.length();
  CGFloat f;
  XCTAssertFalse(ConsumeFloat(&s, &f));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumeFloat_FailureOutsideSinglePrecisionHigh {
  StringPiece s("1e400@@");
  size_t original_length = s.length();
  CGFloat f;
  XCTAssertFalse(ConsumeFloat(&s, &f));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumeFloat_FailureOutsideSinglePrecisionHighNegative {
  StringPiece s("-1e400@@");
  size_t original_length = s.length();
  CGFloat f;
  XCTAssertFalse(ConsumeFloat(&s, &f));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testParseFloat_Success {
  StringPiece s("123.456");
  CGFloat f;
  XCTAssertTrue(ParseFloat(s, &f));
  XCTAssertEqualWithAccuracy(f, 123.456, kTolerance);
}

- (void)testParseFloat_SuccessNegative {
  StringPiece s("-123.456");
  CGFloat f;
  XCTAssertTrue(ParseFloat(s, &f));
  XCTAssertEqualWithAccuracy(f, -123.456, kTolerance);
}

- (void)testParseFloat_Failure {
  StringPiece s("123.456@@");
  CGFloat f;
  XCTAssertFalse(ParseFloat(s, &f));
}

- (void)testConsumeFloats_Success {
  StringPiece s("12.34,56.78-12.34@@");
  CGFloat farray[3];
  XCTAssertTrue(ConsumeFloats(&s, 3, farray));
  XCTAssertEqualWithAccuracy(farray[0], 12.34, kTolerance);
  XCTAssertEqualWithAccuracy(farray[1], 56.78, kTolerance);
  XCTAssertEqualWithAccuracy(farray[2], -12.34, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testParseFloats_Success {
  StringPiece s("12.34,56.78-12.34");
  CGFloat farray[3];
  XCTAssertTrue(ParseFloats(s, 3, farray));
  XCTAssertEqualWithAccuracy(farray[0], 12.34, kTolerance);
  XCTAssertEqualWithAccuracy(farray[1], 56.78, kTolerance);
  XCTAssertEqualWithAccuracy(farray[2], -12.34, kTolerance);
}

- (void)testConsumeFloats_SuccessNoDelimiter {
  // SVG v1.1 specification section 8.3.8 says that floating-point
  // constants without digits before the decimal point are legal.
  StringPiece s("12.3456.78-12.34@@");
  CGFloat farray[3];
  XCTAssertTrue(ConsumeFloats(&s, 3, farray));
  XCTAssertEqual(2U, s.length());
}

- (void)testConsumeLength_SuccessWithUnit {
  StringPiece s("12.34pxx");
  Length l;
  XCTAssertTrue(ConsumeLength(&s, &l));
  XCTAssertEqualWithAccuracy(l.value, 12.34f, kTolerance);
  XCTAssertEqual(l.unit, Length::kUnitPx);
  XCTAssertEqual(s.length(), 1U);
}

- (void)testConsumeLength_SuccessNoUnit {
  StringPiece s("12.34");
  Length l;
  XCTAssertTrue(ConsumeLength(&s, &l));
  XCTAssertEqualWithAccuracy(l.value, 12.34f, kTolerance);
  XCTAssertEqual(l.unit, Length::kUnitNone);
  XCTAssertEqual(s.length(), 0U);
}

- (void)testConsumeLength_FailureNoFloat {
  StringPiece s("px");
  size_t original_length = s.length();
  Length l;
  XCTAssertFalse(ConsumeLength(&s, &l));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testParseLength_FailureIncompleteUnit {
  StringPiece s("12.34p");
  size_t original_length = s.length();
  Length l;
  XCTAssertFalse(ParseLength(s, &l));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testParseLength_FailureWrongUnit {
  StringPiece s("12.34ms");
  size_t original_length = s.length();
  Length l;
  XCTAssertFalse(ParseLength(s, &l));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumeLength_Success {
  StringPiece s("1px 2,3% 4cm@@");
  std::vector<Length> lengths;
  XCTAssertTrue(ConsumeLengths(&s, &lengths));
  XCTAssertEqual(lengths.size(), 4U);
  XCTAssertEqualWithAccuracy(lengths[0].value, 1.f, kTolerance);
  XCTAssertEqual(lengths[0].unit, Length::kUnitPx);
  XCTAssertEqualWithAccuracy(lengths[1].value, 2.f, kTolerance);
  XCTAssertEqual(lengths[1].unit, Length::kUnitNone);
  XCTAssertEqualWithAccuracy(lengths[2].value, 3.f, kTolerance);
  XCTAssertEqual(lengths[2].unit, Length::kUnitPercent);
  XCTAssertEqualWithAccuracy(lengths[3].value, 4.f, kTolerance);
  XCTAssertEqual(lengths[3].unit, Length::kUnitCm);
}

- (void)testConsumeParenthesizedFloats_Success {
  StringPiece s("(12.34,56.78-12.34)@@");
  CGFloat farray[3];
  XCTAssertTrue(ConsumeParenthesizedFloats(&s, 3, farray));
  XCTAssertEqualWithAccuracy(farray[0], 12.34, kTolerance);
  XCTAssertEqualWithAccuracy(farray[1], 56.78, kTolerance);
  XCTAssertEqualWithAccuracy(farray[2], -12.34, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeParenthesizedFloats_FailureNoOpeningParenthesis {
  StringPiece s("12.34,56.78-12.34)@@");
  size_t original_length = s.length();
  CGFloat farray[3];
  XCTAssertFalse(ConsumeParenthesizedFloats(&s, 3, farray));
  XCTAssertEqual(original_length, s.length());
}

- (void)testConsumeParenthesizedFloats_FailureNoClosingParenthesis {
  StringPiece s("(12.34,56.78-12.34@@");
  size_t original_length = s.length();
  CGFloat farray[3];
  XCTAssertFalse(ConsumeParenthesizedFloats(&s, 3, farray));
  XCTAssertEqual(original_length, s.length());
}

- (void)testConsumeAlpha_Success {
  StringPiece s("a@@");
  char c;
  XCTAssertTrue(ConsumeAlpha(&s, &c));
  XCTAssertEqual(c, 'a');
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeAlpha_Failure {
  StringPiece s("@@@");
  char c;
  XCTAssertFalse(ConsumeAlpha(&s, &c));
  XCTAssertEqual(s.length(), 3U);
}

- (void)testConsumeString_Success {
  StringPiece s("foooo");
  const char *string = "foo";
  XCTAssertTrue(ConsumeString(&s, string, true));
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeString_Failure {
  StringPiece s("foooo");
  const char *string = "baz";
  XCTAssertFalse(ConsumeString(&s, string, true));
  XCTAssertEqual(s.length(), 5U);
}

- (void)testConsumeString_Failure_Substring {
  const char *raw_s = "foooo";
  StringPiece s(raw_s, 2);
  const char *string = "foo";
  XCTAssertFalse(ConsumeString(&s, string, true));
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeFlag_SuccessTrue {
  StringPiece s(" 100");
  bool flag;
  XCTAssertTrue(ConsumeFlag(&s, &flag));
  XCTAssertTrue(flag);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeFlag_SuccessFalse {
  StringPiece s(" 000");
  bool flag;
  XCTAssertTrue(ConsumeFlag(&s, &flag));
  XCTAssertFalse(flag);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeFlag_FailureInvalidDigit {
  StringPiece s(" 3@@");
  size_t original_length = s.length();
  bool flag;
  XCTAssertFalse(ConsumeFlag(&s, &flag));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumeFlag_FailureNonDigit {
  StringPiece s(" t@@");
  size_t original_length = s.length();
  bool flag;
  XCTAssertFalse(ConsumeFlag(&s, &flag));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumeString_CaseSensitivity {
  StringPiece s("GooGLE@@");
  XCTAssertTrue(ConsumeString(&s, "GooGLE", true));
  XCTAssertEqual(s.length(), 2U);

  s = "GooGLE@@";
  XCTAssertFalse(ConsumeString(&s, "google", true));
  XCTAssertEqual(s.length(), 8U);

  s = "GooGLE@@";
  XCTAssertTrue(ConsumeString(&s, "google", false));
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeRgbColor_SuccessThreeDigitHex {
  StringPiece s("#aaa@@");
  RgbColor rgb;
  XCTAssertTrue(ConsumeRgbColor(&s, &rgb));
  XCTAssertEqualWithAccuracy(rgb.red(), 0.6667, kTolerance);
  XCTAssertEqualWithAccuracy(rgb.green(), 0.6667, kTolerance);
  XCTAssertEqualWithAccuracy(rgb.blue(), 0.6667, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeRgbColor_SuccessThreeDigitHexWithRemainder {
  StringPiece s("#aaab@@");
  RgbColor rgb;
  XCTAssertTrue(ConsumeRgbColor(&s, &rgb));
  XCTAssertEqualWithAccuracy(rgb.red(), 0.6667, kTolerance);
  XCTAssertEqualWithAccuracy(rgb.green(), 0.6667, kTolerance);
  XCTAssertEqualWithAccuracy(rgb.blue(), 0.6667, kTolerance);
  XCTAssertEqual(s.length(), 3U);
}

- (void)testConsumeRgbColor_SuccessSixDigitsExactly {
  StringPiece s("#FFFFFF@@");
  RgbColor rgb;
  XCTAssertTrue(ConsumeRgbColor(&s, &rgb));
  XCTAssertEqualWithAccuracy(rgb.red(), 1.0, kTolerance);
  XCTAssertEqualWithAccuracy(rgb.green(), 1.0, kTolerance);
  XCTAssertEqualWithAccuracy(rgb.blue(), 1.0, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeRgbColor_SuccessSixDigitHexWithExtraHexDigits {
  StringPiece s("#FFFFFFFF");
  RgbColor rgb;
  XCTAssertTrue(ConsumeRgbColor(&s, &rgb));
  XCTAssertEqualWithAccuracy(rgb.red(), 1.0, kTolerance);
  XCTAssertEqualWithAccuracy(rgb.green(), 1.0, kTolerance);
  XCTAssertEqualWithAccuracy(rgb.blue(), 1.0, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeRgbColor_SuccessFunctional {
  StringPiece s("rgb( 51,102 , 153)@@");
  RgbColor rgb;
  XCTAssertTrue(ConsumeRgbColor(&s, &rgb));
  XCTAssertEqualWithAccuracy(rgb.red(), 0.2, kTolerance);
  XCTAssertEqualWithAccuracy(rgb.green(), 0.4, kTolerance);
  XCTAssertEqualWithAccuracy(rgb.blue(), 0.6, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeRgbColor_SuccessFunctionalPercent {
  StringPiece s("rgb(10%, 20% ,30% )@@");
  RgbColor rgb;
  XCTAssertTrue(ConsumeRgbColor(&s, &rgb));
  XCTAssertEqualWithAccuracy(rgb.red(), 0.1, kTolerance);
  XCTAssertEqualWithAccuracy(rgb.green(), 0.2, kTolerance);
  XCTAssertEqualWithAccuracy(rgb.blue(), 0.3, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeRgbColor_SuccessFunctionalCase {
  StringPiece s("RgB(51, 102, 153)@@");
  RgbColor rgb;
  XCTAssertTrue(ConsumeRgbColor(&s, &rgb));
  XCTAssertEqualWithAccuracy(rgb.red(), 0.2, kTolerance);
  XCTAssertEqualWithAccuracy(rgb.green(), 0.4, kTolerance);
  XCTAssertEqualWithAccuracy(rgb.blue(), 0.6, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

#if SVG_COLOR_KEYWORD_SUPPORT
- (void)testConsumeRgbColor_SuccessStandardColor {
  StringPiece s("  cadetblue@@");
  RgbColor rgb;
  XCTAssertTrue(ConsumeRgbColor(&s, &rgb));
  XCTAssertEqualWithAccuracy(rgb.red(), 0.3725, kTolerance);
  XCTAssertEqualWithAccuracy(rgb.green(), 0.6196, kTolerance);
  XCTAssertEqualWithAccuracy(rgb.blue(), 0.6274, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}

// Because these are described as inherited from CSS, it may be true
// that they're supposed to be case-insensitive even though most SVG
// elements/attributes/values are not.
- (void)testConsumeRgbColor_SuccessStandardColorCase {
  StringPiece s("  mAgEnTa@@");
  RgbColor rgb;
  XCTAssertTrue(ConsumeRgbColor(&s, &rgb));
  XCTAssertEqualWithAccuracy(rgb.red(), 1.0, kTolerance);
  XCTAssertEqualWithAccuracy(rgb.green(), 0.0, kTolerance);
  XCTAssertEqualWithAccuracy(rgb.blue(), 1.0, kTolerance);
  XCTAssertEqual(s.length(), 2U);
}
#endif  // SVG_COLOR_KEYWORD_SUPPORT

- (void)testConsumeRgbColor_FailureNoSharp {
  StringPiece s("ffffff");
  size_t original_length = s.length();
  RgbColor rgb;
  XCTAssertFalse(ConsumeRgbColor(&s, &rgb));
  XCTAssertEqual(original_length, s.length());
}

- (void)testConsumeRgbColor_FailureTooShort {
  StringPiece s("#66");
  size_t original_length = s.length();
  RgbColor rgb;
  XCTAssertFalse(ConsumeRgbColor(&s, &rgb));
  XCTAssertEqual(original_length, s.length());
}

- (void)testConsumeRgbColor_FailureNotHex {
  StringPiece s("#bcs@@");
  size_t original_length = s.length();
  RgbColor rgb;
  XCTAssertFalse(ConsumeRgbColor(&s, &rgb));
  XCTAssertEqual(original_length, s.length());
}

- (void)testConsumeRgbColor_FailureFunctionalInconsistent {
  StringPiece s("rgb(51%, 102, 153%)@@");
  size_t original_length = s.length();
  RgbColor rgb;
  XCTAssertFalse(ConsumeRgbColor(&s, &rgb));
  XCTAssertEqual(original_length, s.length());
}

- (void)testConsumeRgbColor_FailureFunctionalMissingOpenParenthesis {
  StringPiece s("rgb 51, 102, 153)@@");
  size_t original_length = s.length();
  RgbColor rgb;
  XCTAssertFalse(ConsumeRgbColor(&s, &rgb));
  XCTAssertEqual(original_length, s.length());
}

- (void)testConsumeRgbColor_FailureFunctionalMissingCloseParenthesis {
  StringPiece s("rgb(51, 102, 153@@");
  size_t original_length = s.length();
  RgbColor rgb;
  XCTAssertFalse(ConsumeRgbColor(&s, &rgb));
  XCTAssertEqual(original_length, s.length());
}

- (void)testConsumeRgbColor_FailureFunctionalMissingComma {
  StringPiece s("rgb(51 102, 153)@@");
  size_t original_length = s.length();
  RgbColor rgb;
  XCTAssertFalse(ConsumeRgbColor(&s, &rgb));
  XCTAssertEqual(original_length, s.length());
}

- (void)testConsumeRgbColor_FailureFunctionalExtraComma {
  StringPiece s("rgb(51,, 102, 153)@@");
  size_t original_length = s.length();
  RgbColor rgb;
  XCTAssertFalse(ConsumeRgbColor(&s, &rgb));
  XCTAssertEqual(original_length, s.length());
}

- (void)testConsumeRgbColor_FailureStandardColor {
  StringPiece s("frizzlerocks");
  size_t original_length = s.length();
  RgbColor rgb;
  XCTAssertFalse(ConsumeRgbColor(&s, &rgb));
  XCTAssertEqual(original_length, s.length());
}

- (void)testConsumeRgbColor_FailureDigitInTheWay {
  StringPiece s("6green");
  size_t original_length = s.length();
  RgbColor rgb;
  XCTAssertFalse(ConsumeRgbColor(&s, &rgb));
  XCTAssertEqual(original_length, s.length());
}

- (void)testConsumeRgbColor_FailureNull {
  StringPiece s("");
  size_t original_length = s.length();
  RgbColor rgb;
  XCTAssertFalse(ConsumeRgbColor(&s, &rgb));
  XCTAssertEqual(original_length, s.length());
}

- (void)testParseRgbColor_Success {
  StringPiece s("#FFFFFF");
  RgbColor rgb;
  XCTAssertTrue(ParseRgbColor(s, &rgb));
  XCTAssertEqualWithAccuracy(rgb.red(), 1.0, kTolerance);
  XCTAssertEqualWithAccuracy(rgb.green(), 1.0, kTolerance);
  XCTAssertEqualWithAccuracy(rgb.blue(), 1.0, kTolerance);
}

- (void)testParseRgbColor_FailureTooLong {
  StringPiece s("#FFFFFFFF");
  size_t original_length = s.length();
  RgbColor rgb;
  XCTAssertFalse(ParseRgbColor(s, &rgb));
  XCTAssertEqual(original_length, s.length());
}

- (void)testConsumeWhitespace_Success {
  StringPiece s("\n \n@@");
  XCTAssertTrue(ConsumeWhitespace(&s));
  XCTAssertTrue(s == "@@");
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumeWhitespace_Failure {
  StringPiece s("jim brooks");
  XCTAssertFalse(ConsumeWhitespace(&s));
  XCTAssertTrue(s == "jim brooks");
}

- (void)testTrimTrailingWhitespace_Trim {
  StringPiece s("token \n");
  StringPiece st = TrimTrailingWhitespace(s);
  XCTAssertTrue(st == "token");
}

- (void)testTrimTrailingWhitespace_NoTrim {
  StringPiece s("flabbergasted");
  StringPiece st = TrimTrailingWhitespace(s);
  XCTAssertTrue(st == "flabbergasted");
}

- (void)testConsumeIri_Success {
  StringPiece s("url(#SVGID_1_)@@");
  StringPiece iri;
  XCTAssertTrue(ConsumeIri(&s, &iri));
  XCTAssertEqual(s.length(), 2U);
  XCTAssertTrue(iri == "#SVGID_1_", @"%s", iri.as_std_string().c_str());
}

- (void)testConsumeIri_SuccessWhitespace {
  StringPiece s(" url(#SVGID_1_)@@");
  StringPiece iri;
  XCTAssertTrue(ConsumeIri(&s, &iri));
  XCTAssertEqual(s.length(), 2U);
  XCTAssertTrue(iri == "#SVGID_1_", @"%s", iri.as_std_string().c_str());
}

- (void)testConsumeIri_Failure {
  StringPiece s("url($GJGJD");
  size_t original_length = s.length();
  StringPiece iri;
  XCTAssertFalse(ConsumeIri(&s, &iri));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumePreserveAspectRatio_SuccessDeferMinMinMeed {
  StringPiece s("defer xMinYMin meet@@");
  PreserveAspectRatio r;
  XCTAssertTrue(ConsumePreserveAspectRatio(&s, &r));
  XCTAssertTrue(r.defer);
  XCTAssertFalse(r.no_alignment);
  XCTAssertEqual(r.x_alignment, PreserveAspectRatio::kMin);
  XCTAssertEqual(r.y_alignment, PreserveAspectRatio::kMin);
  XCTAssertEqual(r.meet_or_slice, PreserveAspectRatio::kMeet);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumePreserveAspectRatio_SuccessNoneSlice {
  StringPiece s("none slice@@");
  PreserveAspectRatio r;
  XCTAssertTrue(ConsumePreserveAspectRatio(&s, &r));
  XCTAssertFalse(r.defer);
  XCTAssertTrue(r.no_alignment);
  XCTAssertEqual(r.x_alignment, PreserveAspectRatio::kMid);
  XCTAssertEqual(r.y_alignment, PreserveAspectRatio::kMid);
  XCTAssertEqual(r.meet_or_slice, PreserveAspectRatio::kSlice);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumePreserveAspectRatio_SuccessMidMax {
  StringPiece s("xMidYMax@@");
  PreserveAspectRatio r;
  XCTAssertTrue(ConsumePreserveAspectRatio(&s, &r));
  XCTAssertFalse(r.defer);
  XCTAssertFalse(r.no_alignment);
  XCTAssertEqual(r.x_alignment, PreserveAspectRatio::kMid);
  XCTAssertEqual(r.y_alignment, PreserveAspectRatio::kMax);
  XCTAssertEqual(r.meet_or_slice, PreserveAspectRatio::kMeet);
  XCTAssertEqual(s.length(), 2U);
}

- (void)testConsumePreserveAspectRatio_FailureEmptyInput {
  StringPiece s("");
  PreserveAspectRatio r;
  XCTAssertFalse(ConsumePreserveAspectRatio(&s, &r));
  XCTAssertEqual(s.length(), 0U);
}

- (void)testConsumePreserveAspectRatio_FailureNoAlignmentValue {
  StringPiece s("defer slice");
  size_t original_length = s.length();
  PreserveAspectRatio r;
  XCTAssertFalse(ConsumePreserveAspectRatio(&s, &r));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumePreserveAspectRatio_FailureInvalidDefer {
  StringPiece s("deferrr xMidYMid slice");
  size_t original_length = s.length();
  PreserveAspectRatio r;
  XCTAssertFalse(ConsumePreserveAspectRatio(&s, &r));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testConsumePreserveAspectRatio_PartialInvalidAlignment {
  StringPiece s("defer xMidYMidzMid slice");
  PreserveAspectRatio r;
  XCTAssertTrue(ConsumePreserveAspectRatio(&s, &r));
  XCTAssertEqual(s.length(), std::string("zMid slice").size());
}

- (void)testConsumePreserveAspectRatio_PartialInvalidMeetOrSlice {
  StringPiece s("defer xMidYMid meeeeet");
  PreserveAspectRatio r;
  XCTAssertTrue(ConsumePreserveAspectRatio(&s, &r));
  // NOTE: Maybe the space before meeeeet should be kept.
  XCTAssertEqual(s.length(), std::string("meeeeet").size());
}

- (void)testParsePreserveAspectRatio_Success {
  StringPiece s("xMidYMax");
  PreserveAspectRatio r;
  XCTAssertTrue(ParsePreserveAspectRatio(s, &r));
  XCTAssertFalse(r.defer);
  XCTAssertFalse(r.no_alignment);
  XCTAssertEqual(r.x_alignment, PreserveAspectRatio::kMid);
  XCTAssertEqual(r.y_alignment, PreserveAspectRatio::kMax);
  XCTAssertEqual(r.meet_or_slice, PreserveAspectRatio::kMeet);
}

- (void)testParsePreserveAspectRatio_Failre {
  StringPiece s("defer xMidYMid meeeeet");
  PreserveAspectRatio r;
  XCTAssertFalse(ParsePreserveAspectRatio(s, &r));
}

- (void)testNumberDelimiter_SuccessCommaFirst {
  StringPiece s(", @@");
  XCTAssertTrue(ConsumeNumberDelimiter(&s));
  XCTAssertEqual(s.length(), 2U);
}

- (void)testNumberDelimiter_SuccessCommaLast {
  StringPiece s(" ,@@");
  XCTAssertTrue(ConsumeNumberDelimiter(&s));
  XCTAssertEqual(s.length(), 2U);
}

- (void)testNumberDelimiter_DoubleComma {
  StringPiece s(",,@@");
  XCTAssertTrue(ConsumeNumberDelimiter(&s));
  XCTAssertEqual(s.length(), 3U);
}

- (void)testNumberDelimiter_Failure {
  StringPiece s("c@@");
  size_t original_length = s.length();
  XCTAssertFalse(ConsumeNumberDelimiter(&s));
  XCTAssertEqual(s.length(), original_length);
}

- (void)testNumberDelimiter_FailureSpaceOnly {
  StringPiece s(" \t @@");
  size_t original_length = s.length();
  XCTAssertFalse(ConsumeNumberDelimiter(&s));
  XCTAssertEqual(s.length(), original_length);
}

@end
