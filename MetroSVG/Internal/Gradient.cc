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

#include "MetroSVG/Internal/Gradient.h"

#include "MetroSVG/Internal/StringPiece.h"
#include "MetroSVG/Internal/TransformIterator.h"
#include "MetroSVG/Internal/Utils.h"

namespace metrosvg {
namespace internal {

Gradient::Gradient(Gradient::Type type_in, const StringMap &attributes)
    : type(type_in) {
  const std::string *id_value = FindValueOrNull(attributes, std::string("id"));
  if (id_value) {
    id = *id_value;
  }

  const std::string *gradient_transform_value =
      FindValueOrNull(attributes, std::string("gradientTransform"));
  if (gradient_transform_value) {
    StringPiece gradient_transform_value_sp(*gradient_transform_value);
    TransformIterator transform_iterator(&gradient_transform_value_sp);
    while (transform_iterator.Next()) {
      transforms.push_back(transform_iterator.transform());
    }
  }

  const std::string *gradient_units_value =
      FindValueOrNull(attributes, std::string("gradientUnits"));
  if (gradient_units_value != nullptr &&
      *gradient_units_value == "userSpaceOnUse") {
    units = kUnitsUserSpaceOnUse;
  } else {
    units = kUnitsObjectBoundingBox;
  }
}

CGGradientRef CreateCGGradient(const Gradient &gradient) {
  size_t stop_count = gradient.stops.size();
  std::vector<CGFloat> components(stop_count * 4);
  std::vector<CGFloat> locations(stop_count);
  for (size_t i = 0; i < stop_count; ++i) {
    GradientStop stop = gradient.stops[i];
    components[4 * i] = stop.color.red();
    components[4 * i + 1] = stop.color.green();
    components[4 * i + 2] = stop.color.blue();
    components[4 * i + 3] = stop.opacity;
    locations[i] = stop.offset;
  }
  CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
  CGGradientRef cg_gradient =
      CGGradientCreateWithColorComponents(color_space,
                                          components.data(),
                                          locations.data(),
                                          stop_count);
  CGColorSpaceRelease(color_space);
  return cg_gradient;
}

}  // namespace internal
}  // namespace metrosvg
