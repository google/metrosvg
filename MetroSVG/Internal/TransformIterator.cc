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

#include "MetroSVG/Internal/TransformIterator.h"

#include <cmath>

#include "MetroSVG/Internal/BasicValueParsers.h"
#include "MetroSVG/Internal/Macros.h"
#include "MetroSVG/Internal/StringPiece.h"
#include "MetroSVG/Internal/Utils.h"

namespace metrosvg {
namespace internal {

TransformIterator::TransformIterator(StringPiece *s)
    : s_(s), is_first(true) {}

bool TransformIterator::Next() {
  StringPiece s_copy = *s_;
  ConsumeWhitespace(&s_copy);
  if (!is_first) {
    ConsumeTransformDelimeters(&s_copy);
  }
  if (s_copy.length() == 0) {
    return false;
  }
  if (ConsumeString(&s_copy, "matrix", true)) {
    CGFloat elements[6];
    if (!ConsumeParenthesizedFloats(&s_copy, 6, elements)) {
      return false;
    }
    transform_ = CGAffineTransformMake(elements[0], elements[1], elements[2],
                                       elements[3], elements[4], elements[5]);
  } else if (ConsumeString(&s_copy, "translate", true)) {
    CGFloat elements[2];
    if (ConsumeParenthesizedFloats(&s_copy, 2, elements)) {
      transform_ = CGAffineTransformMakeTranslation(elements[0], elements[1]);
    } else if (ConsumeParenthesizedFloats(&s_copy, 1, elements)) {
        transform_ = CGAffineTransformMakeTranslation(elements[0], 0.);
    } else {
      return false;
    }
  } else if (ConsumeString(&s_copy, "scale", true)) {
    CGFloat elements[2];
    if (ConsumeParenthesizedFloats(&s_copy, 2, elements)) {
      transform_ = CGAffineTransformMakeScale(elements[0], elements[1]);
    } else if (ConsumeParenthesizedFloats(&s_copy, 1, elements)) {
      transform_ = CGAffineTransformMakeScale(elements[0], elements[0]);
    } else {
      return false;
    }
  } else if (ConsumeString(&s_copy, "rotate", true)) {
    CGFloat elements[3];
    if (ConsumeParenthesizedFloats(&s_copy, 3, elements)) {
      CGAffineTransform translate =
          CGAffineTransformMakeTranslation(elements[1], elements[2]);
      CGAffineTransform rotate =
          CGAffineTransformMakeRotation(ToRadians(elements[0]));
      CGAffineTransform translate_back =
          CGAffineTransformMakeTranslation(-elements[1], -elements[2]);
      transform_ =
          CGAffineTransformConcat(translate,
                                  CGAffineTransformConcat(rotate,
                                                          translate_back));
    } else if (ConsumeParenthesizedFloats(&s_copy, 1, elements)) {
      transform_ = CGAffineTransformMakeRotation(ToRadians(elements[0]));
    } else {
      return false;
    }
  } else if (ConsumeString(&s_copy, "skewX", true)) {
    CGFloat skew_angle;
    if (!ConsumeParenthesizedFloats(&s_copy, 1, &skew_angle)) {
      return false;
    }
    CGFloat skew_angle_radians = ToRadians(skew_angle);
    transform_ = CGAffineTransformMake(1, 0, tan(skew_angle_radians), 1, 0, 0);
  } else if (ConsumeString(&s_copy, "skewY", true)) {
    CGFloat skew_angle;
    if (!ConsumeParenthesizedFloats(&s_copy, 1, &skew_angle)) {
      return false;
    }
    CGFloat skew_angle_radians = ToRadians(skew_angle);
    transform_ = CGAffineTransformMake(1, tan(skew_angle_radians), 0, 1, 0, 0);
  } else {
    return false;
  }
  s_->Advance(s_copy.begin() - s_->begin());
  is_first = false;
  return true;
}

void TransformIterator::ConsumeTransformDelimeters(StringPiece *s) const {
  while (true) {
    ConsumeWhitespace(s);
    if (s->length() > 0 && (*s)[0] == ',') {
      s->Advance(1);
    } else {
      break;
    }
  }
  ConsumeWhitespace(s);
}

}  // namespace internal
}  // namespace metrosvg
