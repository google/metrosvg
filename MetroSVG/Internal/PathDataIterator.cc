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

#include "MetroSVG/Internal/PathDataIterator.h"

#include <cmath>

#include "MetroSVG/Internal/BasicValueParsers.h"
#include "MetroSVG/Internal/Macros.h"
#include "MetroSVG/Internal/StringPiece.h"

namespace metrosvg {
namespace internal {

PathDataIterator::PathDataIterator(const char *data,
                                   PathDataFormat format,
                                   bool implicit_close)
    : s_(data),
      implicit_close_(implicit_close),
      format_(format),
      is_first_command_(true),
      absolute_(format == kPathDataFormatPoints),
      shown_close_path_(false),
      last_command_type_(kPathCommandTypeClosePath) {
  point_ = CGPointMake(0.0, 0.0);
}

bool PathDataIterator::Next() {
  ConsumeWhitespace(&s_);
  if (s_.length() == 0) {
    if (implicit_close_ && !shown_close_path_) {
      command_type_ = kPathCommandTypeClosePath;
      shown_close_path_ = true;
      return true;
    } else {
      return false;
    }
  }

  bool success;
  if (format_ == kPathDataFormatPoints) {
    success = ParseSingleCommandForPoints();
  } else {
    success = ParseSingleCommandForPath();
  }
  if (success) {
    is_first_command_ = false;
    last_command_type_ = command_type_;
  }
  return success;
}

bool PathDataIterator::ParseSingleCommandForPath() {
  char command_char;
  // See whether we're starting a new command or repeating the previous command.
  if (PeekAlpha(s_, &command_char)) {
    // Consume the char we just peeked.
    if (!ConsumeAlpha(&s_, &command_char)) {
      return false;
    }
    char normalized_command_char = command_char;
    absolute_ = false;
    if ('A' <= command_char && command_char <= 'Z') {
      absolute_ = true;
      normalized_command_char = command_char - ('A' - 'a');
    }
    switch (normalized_command_char) {
      case 'c':
        command_type_ = kPathCommandTypeCubicBezier;
        break;
      case 'h':
        command_type_ = kPathCommandTypeHorizontalLineTo;
        break;
      case 'l':
        command_type_ = kPathCommandTypeLineTo;
        break;
      case 'v':
        command_type_ = kPathCommandTypeVerticalLineTo;
        break;
      case 'm':
        command_type_ = kPathCommandTypeMoveTo;
        break;
      case 's':
        command_type_ = kPathCommandTypeShorthandCubicBezier;
        break;
      case 'q':
        command_type_ = kPathCommandTypeQuadBezier;
        break;
      case 't':
        command_type_ = kPathCommandTypeShorthandQuadBezier;
        break;
      case 'a':
        command_type_ = kPathCommandTypeEllipticalArc;
        break;
      case 'z':
        command_type_ = kPathCommandTypeClosePath;
        break;
      default:
        return false;
    }
  } else {
    if (is_first_command_ || (command_type_ == kPathCommandTypeClosePath)) {
      return false;
    }
    // All other command types can repeat their arguments, so reuse the last
    // command type.  However, if the last type was MoveTo, it should morph into
    // a LineTo (see SVG 1.1 Section 8.3.2).
    if (command_type_ == kPathCommandTypeMoveTo) {
      command_type_ = kPathCommandTypeLineTo;
    }
    // Consume any comma between repeats.
    ConsumeNumberDelimiter(&s_);
  }
  switch (command_type_) {
    case kPathCommandTypeMoveTo: {
      bool success = ParseMoveAndLineCommand(command_type_);
      subpath_start_point_ = point_;
      return success;
    }
    case kPathCommandTypeLineTo:
    case kPathCommandTypeHorizontalLineTo:
    case kPathCommandTypeVerticalLineTo:
      return ParseMoveAndLineCommand(command_type_);
    case kPathCommandTypeCubicBezier:
      return ParseCubicBezierCommand();
    case kPathCommandTypeShorthandCubicBezier:
      return ParseShorthandCubicBezierCommand();
    case kPathCommandTypeQuadBezier:
      return ParseQuadBezierCommand();
    case kPathCommandTypeShorthandQuadBezier:
      return ParseShorthandQuadBezierCommand();
    case kPathCommandTypeEllipticalArc:
      return ParseEllipticalArcCommand();
    case kPathCommandTypeClosePath:
      // The default start point of the next subpath is the same as
      // the current subpath. SVG (see SVG 1.1 Section 8.3.3) and
      // Core Graphics share this behivior.
      point_ = subpath_start_point_;
      return true;
  }
}

bool PathDataIterator::ParseSingleCommandForPoints() {
  if (is_first_command_) {
    command_type_ = kPathCommandTypeMoveTo;
  } else {
    command_type_ = kPathCommandTypeLineTo;
    // Consume any number delimiter between points.
    ConsumeNumberDelimiter(&s_);
  }
  return ParseMoveAndLineCommand(command_type_);
}

bool PathDataIterator::ParseMoveAndLineCommand(
    enum PathCommandType command_type) {
  bool change_x = false;
  bool change_y = false;
  CGFloat values[2] = {point_.x , point_.y};
  switch (command_type) {
    case kPathCommandTypeHorizontalLineTo:
      if (!ConsumeFloat(&s_, values)) {
        return false;
      }
      change_x = true;
      break;
    case kPathCommandTypeLineTo:
      if (!ConsumeFloats(&s_, 2, values)) {
        return false;
      }
      change_x = true;
      change_y = true;
      break;
    case kPathCommandTypeMoveTo:
      if (!ConsumeFloats(&s_, 2, values)) {
        return false;
      }
      change_x = true;
      change_y = true;
      break;
    case kPathCommandTypeVerticalLineTo:
      if (!ConsumeFloat(&s_, values + 1)) {
        return false;
      }
      change_y = true;
      break;
    default:
      return false;
  }
  if (absolute_) {
    if (change_x) {
      point_ = CGPointMake(values[0], point_.y);
    }
    if (change_y) {
      point_ = CGPointMake(point_.x, values[1]);
    }
  } else {
    if (change_x) {
      point_ = CGPointMake(point_.x + values[0], point_.y);
    }
    if (change_y) {
      point_ = CGPointMake(point_.x, point_.y + values[1]);
    }
  }
  return true;
}

bool PathDataIterator::ParseCubicBezierCommand() {
  CGFloat values[6];
  if (!ConsumeFloats(&s_, ARRAYSIZE(values), values)) {
    return false;
  }
  control_point1_ = CGPointMake(values[0] + (absolute_ ? 0 : point_.x),
                                values[1] + (absolute_ ? 0 : point_.y));
  control_point2_ = CGPointMake(values[2] + (absolute_ ? 0 : point_.x),
                                values[3] + (absolute_ ? 0 : point_.y));
  point_ = CGPointMake(values[4] + (absolute_ ? 0 : point_.x),
                       values[5] + (absolute_ ? 0 : point_.y));
  return true;
}

bool PathDataIterator::ParseShorthandCubicBezierCommand() {
  CGFloat values[4];
  if (!ConsumeFloats(&s_, ARRAYSIZE(values), values)) {
    return false;
  }
  if (last_command_type_ == kPathCommandTypeCubicBezier ||
      last_command_type_ == kPathCommandTypeShorthandCubicBezier) {
    control_point1_ = CGPointMake(point_.x + (point_.x - control_point2_.x),
                                  point_.y + (point_.y - control_point2_.y));
  } else {
    control_point1_ = point_;
  }
  control_point2_ = CGPointMake(values[0] + (absolute_ ? 0 : point_.x),
                                values[1] + (absolute_ ? 0 : point_.y));
  point_ = CGPointMake(values[2] + (absolute_ ? 0 : point_.x),
                       values[3] + (absolute_ ? 0 : point_.y));
  return true;
}

bool PathDataIterator::ParseQuadBezierCommand() {
  CGFloat values[4];
  if (!ConsumeFloats(&s_, ARRAYSIZE(values), values)) {
    return false;
  }
  control_point1_ = CGPointMake(values[0] + (absolute_ ? 0 : point_.x),
                                values[1] + (absolute_ ? 0 : point_.y));
  point_ = CGPointMake(values[2] + (absolute_ ? 0 : point_.x),
                       values[3] + (absolute_ ? 0 : point_.y));
  return true;
}

bool PathDataIterator::ParseShorthandQuadBezierCommand() {
  CGFloat values[2];
  if (!ConsumeFloats(&s_, ARRAYSIZE(values), values)) {
    return false;
  }
  if (last_command_type_ == kPathCommandTypeQuadBezier ||
      last_command_type_ == kPathCommandTypeShorthandQuadBezier) {
    control_point1_ = CGPointMake(point_.x + (point_.x - control_point1_.x),
                                  point_.y + (point_.y - control_point1_.y));
  } else {
    control_point1_ = point_;
  }
  point_ = CGPointMake(values[0] + (absolute_ ? 0 : point_.x),
                       values[1] + (absolute_ ? 0 : point_.y));
  return true;
}

bool PathDataIterator::ParseEllipticalArcCommand() {
  CGFloat values[3];
  if (!ConsumeFloats(&s_, ARRAYSIZE(values), values)) {
    return false;
  }
  // Take absolute values per spec.
  // http://www.w3.org/TR/SVG11/implnote.html#ArcImplementationNotes
  arc_radius_x_ = std::fabs(values[0]);
  arc_radius_y_ = std::fabs(values[1]);
  if (arc_radius_x_ == 0 || arc_radius_y_ == 0) {
    return false;
  }
  rotation_ = values[2];

  ConsumeNumberDelimiter(&s_);
  if (!ConsumeFlag(&s_, &large_arc_)) {
    return false;
  }

  ConsumeNumberDelimiter(&s_);
  if (!ConsumeFlag(&s_, &sweep_)) {
    return false;
  }

  ConsumeNumberDelimiter(&s_);
  CGFloat point_coords[2];
  if (!ConsumeFloats(&s_, ARRAYSIZE(point_coords), point_coords)) {
    return false;
  }
  point_ = CGPointMake(point_coords[0] + (absolute_ ? 0 : point_.x),
                       point_coords[1] + (absolute_ ? 0 : point_.y));
  return true;
}

}  // namespace internal
}  // namespace metrosvg
