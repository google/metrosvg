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

#include <map>
#include <string>
#include <vector>

#include <CoreGraphics/CoreGraphics.h>

namespace metrosvg {
namespace internal {

typedef std::map<std::string, std::string> StringMap;

// RgbColor represents a color in the RGB color space.
// Intensity of each color component takes a value from 0.0 to 1.0.
class RgbColor {
 public:
  RgbColor()
      : red_(0), green_(0), blue_(0) {}

  RgbColor(CGFloat red, CGFloat green, CGFloat blue);

  CGFloat red() const { return red_; }
  void set_red(CGFloat red) { red_ = red; }

  CGFloat green() const { return green_; }
  void set_green(CGFloat green) { green_ = green; }

  CGFloat blue() const { return blue_; }
  void set_blue(CGFloat blue) { blue_ = blue; }

 private:
  CGFloat red_;
  CGFloat green_;
  CGFloat blue_;
};

struct Length {
  enum Unit {
    kUnitNone = 0,

    kUnitCm,
    kUnitEm,
    kUnitEx,
    kUnitIn,
    kUnitMm,
    kUnitPc,
    kUnitPercent,
    kUnitPt,
    kUnitPx,
  };

  CGFloat value;
  Unit unit;

  Length()
      : value(0), unit(kUnitNone) {}
  Length(CGFloat value_in, Unit unit_in)
      : value(value_in), unit(unit_in) {}
};

struct LineDash {
  std::vector<CGFloat> dash_values;
  CGFloat phase;

  LineDash()
      : phase(0) {}
};

enum FillRule {
  kFillRuleNonZero,
  kFillRuleEvenOdd,
};

// Parsed value of the preserveAspectRatio attribute.
struct PreserveAspectRatio {
  bool defer;
  bool no_alignment;  // true if alignment value is "none".

  enum Alignment {
    kMin,
    kMid,
    kMax,
  };
  Alignment x_alignment;  // must be kMid if no_alignment is true.
  Alignment y_alignment;  // must be kMid if no_alignment is true.

  enum MeetOrSlice {
    kMeet,
    kSlice,
  };
  MeetOrSlice meet_or_slice;

  static PreserveAspectRatio default_value() {
    PreserveAspectRatio aspect_ratio;
    aspect_ratio.defer = false;
    aspect_ratio.no_alignment = false;
    aspect_ratio.x_alignment = kMid;
    aspect_ratio.y_alignment = kMid;
    aspect_ratio.meet_or_slice = kMeet;
    return aspect_ratio;
  }
};

}  // namespace internal
}  // namespace metrosvg
