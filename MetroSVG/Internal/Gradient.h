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

#include <string>
#include <vector>

#include <CoreGraphics/CoreGraphics.h>

#include "MetroSVG/Internal/BasicTypes.h"

namespace metrosvg {
namespace internal {

struct Gradient;

CGGradientRef CreateCGGradient(const Gradient &gradient);

struct GradientStop {
  CGFloat offset;
  RgbColor color;
  CGFloat opacity;

  GradientStop(CGFloat offset_in, RgbColor color_in, CGFloat opacity_in)
      : offset(offset_in), color(color_in), opacity(opacity_in) {}
};

struct Gradient {
  enum Type {
    kTypeLinear,
    kTypeRadial,
  };

  enum Units {
    kUnitsObjectBoundingBox,
    kUnitsUserSpaceOnUse,
  };

  struct Linear {
    Length x1, y1, x2, y2;
  };

  struct Radial {
    Length fx, fy, cx, cy, r;
  };

  Type type;
  std::string id;
  std::vector<GradientStop> stops;
  std::vector<CGAffineTransform> transforms;
  Units units;

  union {
    Linear linear;
    Radial radial;
  };

  Gradient(Type type_in, const StringMap &attributes);
};

}  // namespace internal
}  // namespace metrosvg
