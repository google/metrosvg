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

#pragma once

#include <algorithm>
#include <cstring>
#include <vector>

#include <CoreGraphics/CoreGraphics.h>

#include "MetroSVG/Internal/BasicTypes.h"
#include "MetroSVG/Internal/StringPiece.h"
// Must include this here to get default value of SVG_COLOR_KEYWORD_SUPPORT.
#include "MetroSVG/Internal/SVGStandardColor.h"

namespace metrosvg {
namespace internal {

// There are conventions for naming functions in this file.
//
// A function named "Consume<token>" takes a string pointer. It returns
// whether or not a token of the given type was found at the beginning of
// the string. Except where noted, it ignores any whitespace found before
// the token. If the token was found, it advances the string pointer past
// the token and returns the parsed value of the token via an argument.
//
// A function named "Parse<token>" takes a string by value. It returns
// whether or not the string consists entirely of the given token. Except
// where noted, it ignores any whitespace found before the token. If the
// token was found, it returns the parsed value of the token via an argument.

// Consumes a minus sign "-".
bool ConsumeSign(StringPiece *s);

// Consumes a non-negative decimal integer value, e.g., "0", "439".
bool ConsumeDecimalInt(StringPiece *s, int *n);

// Consumes a non-negative decimal integer value followed by a percent
// symbol, e.g., "0%", "12%", "100%", "1249%".
bool ConsumeDecimalIntPercent(StringPiece *s, int *n);

// Consumes a hexadecimal integer of the given width, e.g, "1fd0", "deadbeaf".
// If a zero or negative width is given, parses as many hex digits as
// available.
bool ConsumeHexInt(StringPiece *s, int width, int *n);

// Consumes or parses a float value, e.g., "0.", "13.3", "-.2", "9.41-e3".
bool ConsumeFloat(StringPiece *s, CGFloat *f);
bool ParseFloat(StringPiece s, CGFloat *f);

// Consumes or parses the given number of floats separated by commas,
// e.g., "-0.5., 65.2".
bool ConsumeFloats(StringPiece *s, int count, CGFloat *farray);
bool ParseFloats(StringPiece s, int count, CGFloat *farray);

// Parses the given number of floats surrounded by parentheses,
// e.g., "(-0.5., 65.2)".
bool ConsumeParenthesizedFloats(StringPiece *s,
                                int count,
                                CGFloat *farray);

// Consumes or parses a float value followed by a length unit,
// e.g., "5.6in", "-12px".
bool ConsumeLength(StringPiece *s, Length *length);
bool ParseLength(StringPiece s, Length *length);

// Consumes or parses a list of lengths.
bool ConsumeLengths(StringPiece *s, std::vector<Length> *lengths);
bool ParseLengths(StringPiece s, std::vector<Length> *lengths);

// PeekAlpha returns whether the first char in the string is an English
// alphabetical character. It does not ignore whitespace.  If the return
// value is true, it will return that character via the argument.
bool PeekAlpha(StringPiece s, char *c);

// ConsumeAlpha returns the same value as PeekAlpha, but also advances
// the string past the character if the return value is true.
bool ConsumeAlpha(StringPiece *s, char *c);

// Consumes a string value. It does not ignore whitespace.
bool ConsumeString(StringPiece *s, const char *string, bool case_sensitive);

// Consumes a single-digit flag value used by elliptical arcs.
bool ConsumeFlag(StringPiece *s, bool *flag);

// Consumes or parses a color value. Values allowed for color can be found on
// http://www.w3.org/TR/SVG11/types.html#DataTypeColor
bool ConsumeRgbColor(StringPiece *s, RgbColor *rgb);
bool ParseRgbColor(StringPiece s, RgbColor *rgb);

bool ConsumeWhitespace(StringPiece *s);
StringPiece TrimTrailingWhitespace(const StringPiece &s);

bool ConsumeIri(StringPiece *s, StringPiece *iri);
bool ParseIri(StringPiece s, StringPiece *iri);

// Consumes or parses a value of the preserveAspectRatio attribute.
bool ConsumePreserveAspectRatio(StringPiece *s,
                                PreserveAspectRatio *aspect_ratio);
bool ParsePreserveAspectRatio(StringPiece s,
                              PreserveAspectRatio *aspect_ratio);

bool ConsumeNumberDelimiter(StringPiece *s);

}  // namespace internal
}  // namespace metrosvg
