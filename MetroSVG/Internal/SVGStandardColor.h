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

#include "MetroSVG/Internal/StringPiece.h"

// If this symbol is externally set to 0, SVG color keyword support
// will be omitted.  Color keyword support causes the object code
// size to increase by about 1100 bytes.
#if !defined(SVG_COLOR_KEYWORD_SUPPORT)
#define SVG_COLOR_KEYWORD_SUPPORT 1
#endif  // !defined(SVG_COLOR_KEYWORD_SUPPORT)

#if SVG_COLOR_KEYWORD_SUPPORT

namespace metrosvg {
namespace internal {

  // This is a struct that can be statically initialized with the
// definitions of the standard SVG colors.
struct SvgStandardColorDefinition {
  const char *name;
  uint8_t red;
  uint8_t green;
  uint8_t blue;
  uint8_t alpha;
};
const SvgStandardColorDefinition *FindSVGStandardColorOrNull(
    const StringPiece &token);

}  // namespace internal
}  // namespace metrosvg

#endif  // SVG_COLOR_KEYWORD_SUPPORT
