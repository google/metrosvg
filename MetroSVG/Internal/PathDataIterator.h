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

#include <CoreGraphics/CoreGraphics.h>

#include "MetroSVG/Internal/StringPiece.h"

namespace metrosvg {
namespace internal {

class StringPiece;

// PathCommandType represents the path commands defined by the SVG
// specification.
//
// NOTE: The client of PathDataIterator doesn't need distinction between
// some of these commands. Maybe consolidating these values will make the
// class interface cleaner and consistent.
enum PathCommandType {
  kPathCommandTypeMoveTo = 0,
  kPathCommandTypeLineTo = 1,
  kPathCommandTypeHorizontalLineTo = 2,
  kPathCommandTypeVerticalLineTo = 3,
  kPathCommandTypeCubicBezier = 4,
  kPathCommandTypeShorthandCubicBezier = 5,
  kPathCommandTypeQuadBezier = 6,
  kPathCommandTypeShorthandQuadBezier = 7,
  kPathCommandTypeEllipticalArc = 8,
  kPathCommandTypeClosePath = 9,
};

enum PathDataFormat {
  kPathDataFormatPoints = 0,  // polyline or polygon
  kPathDataFormatPath = 1,  // path
};

class PathDataIterator {
 public:
  // format defines whether is a path with full path commands, or a points
  // element with simply x,y pairs.
  // implicit_close means that an implicit ClosePath command should be appended
  // to the commands found in the data.
  PathDataIterator(const char *data, PathDataFormat format,
                   bool implicit_close);

  bool Next();

  PathCommandType command_type() const { return command_type_; }
  CGPoint point() const { return point_; }
  CGPoint control_point1() const { return control_point1_; }
  CGPoint control_point2() const { return control_point2_; }
  // Those four functions are for drawing arcs.
  CGFloat arc_radius_x() const { return arc_radius_x_; }
  CGFloat arc_radius_y() const { return arc_radius_y_; }
  bool large_arc() const { return large_arc_; }
  bool sweep() const { return sweep_; }
  CGFloat rotation() const { return rotation_; }

 private:
  StringPiece s_;
  bool implicit_close_, large_arc_, sweep_;
  PathDataFormat format_;
  PathCommandType command_type_;
  CGPoint point_, control_point1_, control_point2_;
  CGFloat arc_radius_x_;
  CGFloat arc_radius_y_;
  CGFloat rotation_;

  // For interpreting paths.
  bool is_first_command_;
  bool absolute_;  // Always true for polygon/polyline.
  bool shown_close_path_;  // Always true for polygon/polyline.
  CGPoint subpath_start_point_;
  // This has a valid value only when is_first_command_ is true.
  PathCommandType last_command_type_;

  bool ParseSingleCommandForPath();
  bool ParseSingleCommandForPoints();

  // The following routines assume the command character has already been
  // consumed from the StringPiece.

  // For ParseMoveAndLineCommand, command_type must be one of MoveTo, LineTo,
  // HorizontalLineTo, or VerticalLineTo.
  bool ParseMoveAndLineCommand(enum PathCommandType command_type);
  bool ParseCubicBezierCommand();
  bool ParseShorthandCubicBezierCommand();
  bool ParseQuadBezierCommand();
  bool ParseShorthandQuadBezierCommand();
  bool ParseEllipticalArcCommand();
};

}  // namespace internal
}  // namespace metrosvg
