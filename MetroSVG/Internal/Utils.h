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

#include <cmath>
#include <map>

#include <CoreGraphics/CoreGraphics.h>

#include "MetroSVG/Internal/BasicTypes.h"
#include "MetroSVG/Internal/Constants.h"
#include "MetroSVG/MetroSVG.h"

namespace metrosvg {
namespace internal {

// This function makes it easier to use unique_ptr with a custom deleter.
template<typename T, typename Deleter>
std::unique_ptr<T, Deleter> MakeUniquePtr(T *t, Deleter deleter) {
  std::unique_ptr<T, Deleter> p(t, deleter);
  return p;
}

template<typename KeyType, typename ValueType>
const ValueType *FindValueOrNull(const std::map<KeyType, ValueType> &map,
                                 const KeyType &key) {
  typename std::map<KeyType, ValueType>::const_iterator iter = map.find(key);
  if (iter == map.end()) {
    return NULL;
  } else {
    return &(iter->second);
  }
}

// This function will look for the given key in the given map.
// If it is present, it will attempt to parse the value of the
// key as a floating-point number.
// If the key is present and the parse is successful, it will
// set the value pointed to by |out_float| and return true.
// If the key is not present or if the value does not represent
// a floating-point number, it will return false and the value
// pointed to by |out_float| will be unchanged.
bool FloatValueForKey(const StringMap &map,
                      const std::string &key,
                      CGFloat *out_float);

bool LengthValueForKey(const StringMap &map,
                       const std::string &key,
                       Length *out_length);

static inline CGFloat ToRadians(CGFloat degrees) {
  return degrees * kPi / 180.f;
}

static inline CGFloat ClampToUnitRange(CGFloat value) {
  return std::fmin(std::fmax(value, 0.f), 1.f);
}

// Converts representaion of an arc in start point,
// end point and flags that is used by SVG to one by center,
// Radius, start angle and end angle that is used by Core Graphics.
// Angles are in radians.
// Returns false in case of bad input.
bool SvgArcToCgArc(CGPoint start_point,
                   CGPoint end_point,
                   bool large_arc,
                   bool sweep,
                   CGFloat *radius,
                   CGPoint *center,
                   CGFloat *start_angle,
                   CGFloat *end_angle);

// Test that angle a1 is close to angle a2.
// When the difference between a1 and a2 is more than 2 * pi,
// a1 is shifted to a point near a2 by multiples of 2 * pi.
bool AreAnglesClose(CGFloat a1, CGFloat a2, CGFloat accuracy);

// Returns an affine transform that maps a given rectangle to
// a unit rectangle located at the origin ((0, 0), (1, 1)).
CGAffineTransform CGAffineTransformToNormalizeRect(CGRect rect);

// Returns a transform to establish a new coordinate system
// as specified by |aspect_ratio| and |view_box| within the |target_viewport|
// described by the current coordinate system.
// NOTE: This method currently only supports view box and viewport
// place at the origin.
// TODO: Implement this missing feature.
CGAffineTransform
CGAffineTransformForPreserveAspectRatio(PreserveAspectRatio aspect_ratio,
                                        CGRect view_box,
                                        CGRect target_viewport);

// Returns a unit-less length value measured in the user space evaluating
// a given length value with a unit. Currently, only conversion from a
// percentage, e.g., 65% -> 0.65, is supported.
CGFloat EvaluateLength(Length length);

}  // namespace internal
}  // namespace metrosvg
