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

#include "MetroSVG/Internal/BasicTypes.h"

#include "MetroSVG/Internal/Utils.h"

namespace metrosvg {
namespace internal {

RgbColor::RgbColor(CGFloat red, CGFloat green, CGFloat blue)
    : red_(ClampToUnitRange(red)),
      green_(ClampToUnitRange(green)),
      blue_(ClampToUnitRange(blue)) {}

}  // namespace internal
}  // namespace metrosvg
