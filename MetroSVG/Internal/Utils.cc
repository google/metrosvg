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

#include "MetroSVG/Internal/Utils.h"

#include <cmath>

#include "MetroSVG/Internal/BasicValueParsers.h"
#include "MetroSVG/Internal/Constants.h"
#include "MetroSVG/Internal/StringPiece.h"

namespace metrosvg {
namespace internal {

bool FloatValueForKey(const StringMap &map,
                      const std::string &key,
                      CGFloat *out_float) {
  const std::string *value = FindValueOrNull(map, key);
  if (value) {
    return ParseFloat(StringPiece(*value), out_float);
  }
  return false;
}

bool LengthValueForKey(const StringMap &map,
                       const std::string &key,
                       Length *out_length) {
  const std::string *value = FindValueOrNull(map, key);
  if (value) {
    return ParseLength(StringPiece(*value), out_length);
  }
  return false;
}

bool SvgArcToCgArc(CGPoint start_point,
                   CGPoint end_point,
                   bool large_arc,
                   bool sweep,
                   CGFloat *radius,
                   CGPoint *center,
                   CGFloat *start_angle,
                   CGFloat *end_angle) {
  if (CGPointEqualToPoint(start_point, end_point) || *radius <= 0) {
    return false;
  }
  CGFloat horizontal_length =
      std::sqrt(std::pow(start_point.x - end_point.x, 2.f)
          + std::pow(start_point.y - end_point.y, 2.f));
  // If vertical_length has no solution,
  // the radius should be scaled up to the diameter.
  // http://www.w3.org/TR/SVG11/implnote.html#ArcImplementationNotes
  while (pow(*radius, 2) - pow(horizontal_length / 2, 2) < 0) {
    *radius = horizontal_length / 2;
  }
  CGFloat vertical_length =
      std::sqrt(std::pow(*radius, 2.f) - std::pow(horizontal_length / 2, 2.f));
  if (large_arc != sweep) vertical_length = -vertical_length;
  center->x = (start_point.x + end_point.x) / 2
      +(end_point.y - start_point.y) * vertical_length / horizontal_length;
  center->y = (start_point.y + end_point.y) / 2
      - (end_point.x - start_point.x) * vertical_length / horizontal_length;
  *start_angle += atan2(-center->y + start_point.y, start_point.x - center->x);
  *end_angle += atan2(-center->y + end_point.y, end_point.x - center->x);

  return true;
}

bool AreAnglesClose(CGFloat a1, CGFloat a2, CGFloat accuracy) {
  int round_count = static_cast<int>(std::round((a2 - a1) / (2 * kPi)));
  a1 += 2 * kPi * round_count;
  return (std::fabs(a1 - a2) < accuracy);
}

CGAffineTransform CGAffineTransformToNormalizeRect(CGRect rect) {
  CGAffineTransform transform =
      CGAffineTransformMakeTranslation(CGRectGetMinX(rect),
                                       CGRectGetMinY(rect));
  transform = CGAffineTransformScale(transform, CGRectGetWidth(rect),
                                     CGRectGetHeight(rect));
  return transform;
}

namespace {
CGFloat OffsetForAlignment(PreserveAspectRatio::Alignment alignment,
                           CGFloat viewport_dimention,
                           CGFloat object_dimention) {
  switch (alignment) {
    case PreserveAspectRatio::kMin:
      return 0;
    case PreserveAspectRatio::kMid:
      return (viewport_dimention - object_dimention) / 2;
    case PreserveAspectRatio::kMax:
      return viewport_dimention - object_dimention;
  }
}
}  // namespace

CGAffineTransform
CGAffineTransformForPreserveAspectRatio(PreserveAspectRatio aspect_ratio,
                                        CGRect view_box,
                                        CGRect target_viewport) {
  CGFloat x_scale =
      CGRectGetWidth(target_viewport) / CGRectGetWidth(view_box);
  CGFloat y_scale =
      CGRectGetHeight(target_viewport) / CGRectGetHeight(view_box);
  if (!aspect_ratio.no_alignment) {
    CGFloat scale =
        (aspect_ratio.meet_or_slice == PreserveAspectRatio::kMeet) ?
        std::fmin(x_scale, y_scale) :
        std::fmax(x_scale, y_scale);
    x_scale = scale;
    y_scale = scale;
  }

  CGFloat scaled_width = x_scale * CGRectGetWidth(view_box);
  CGFloat x_offset = OffsetForAlignment(aspect_ratio.x_alignment,
                                        CGRectGetWidth(target_viewport),
                                        scaled_width);
  CGFloat scaled_height = y_scale * CGRectGetHeight(view_box);
  CGFloat y_offset = OffsetForAlignment(aspect_ratio.y_alignment,
                                        CGRectGetHeight(target_viewport),
                                        scaled_height);

  CGAffineTransform transform =
      CGAffineTransformMakeTranslation(x_offset, y_offset);
  transform = CGAffineTransformScale(transform, x_scale, y_scale);
  return transform;
}

CGFloat EvaluateLength(Length length) {
  CGFloat scale = 1.f;
  if (length.unit == Length::kUnitPercent) {
    scale = 0.01f;
  }
  return length.value * scale;
}

}  // namespace internal
}  // namespace metrosvg
