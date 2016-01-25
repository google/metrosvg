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

#include "MetroSVG/Internal/LoggingUtils.h"

#include <CoreGraphics/CoreGraphics.h>

namespace metrosvg {
namespace internal {

std::string FormatArgs() {
  return "";
}

std::string FormatArgs(const LogArg &arg1) {
  return arg1.string_value();
}

std::string FormatArgs(const LogArg &arg1, const LogArg &arg2) {
  std::stringstream ss;
  ss << arg1.string_value() << ", " << arg2.string_value();
  return ss.str();
}

std::string FormatArgs(const LogArg &arg1, const LogArg &arg2,
                       const LogArg &arg3) {
  std::stringstream ss;
  ss << arg1.string_value() << ", " << arg2.string_value() << ", "
     << arg3.string_value();
  return ss.str();
}

std::string FormatArgs(const LogArg &arg1, const LogArg &arg2,
                       const LogArg &arg3, const LogArg &arg4) {
  std::stringstream ss;
  ss << arg1.string_value() << ", " << arg2.string_value() << ", "
     << arg3.string_value() << ", " << arg4.string_value();
  return ss.str();
}

std::string FormatArgs(const LogArg &arg1, const LogArg &arg2,
                       const LogArg &arg3, const LogArg &arg4,
                       const LogArg &arg5) {
  std::stringstream ss;
  ss << arg1.string_value() << ", " << arg2.string_value() << ", "
     << arg3.string_value() << ", " << arg4.string_value() << ", "
     << arg5.string_value();
  return ss.str();
}

std::string FormatArgs(const LogArg &arg1, const LogArg &arg2,
                       const LogArg &arg3, const LogArg &arg4,
                       const LogArg &arg5, const LogArg &arg6) {
  std::stringstream ss;
  ss << arg1.string_value() << ", " << arg2.string_value() << ", "
     << arg3.string_value() << ", " << arg4.string_value() << ", "
     << arg5.string_value() << ", " << arg6.string_value();
  return ss.str();
}

std::string FormatArgs(const LogArg &arg1, const LogArg &arg2,
                       const LogArg &arg3, const LogArg &arg4,
                       const LogArg &arg5, const LogArg &arg6,
                       const LogArg &arg7) {
  std::stringstream ss;
  ss << arg1.string_value() << ", " << arg2.string_value() << ", "
     << arg3.string_value() << ", " << arg4.string_value() << ", "
     << arg5.string_value() << ", " << arg6.string_value() << ", "
     << arg7.string_value();
  return ss.str();
}

template<>
std::string FormatValue(std::nullptr_t value) {
  return "NULL";
}

template<>
std::string FormatValue(const CGAffineTransform value) {
  std::stringstream ss;
  ss << "(" << value.a << ", " << value.b << ", "
     << value.c << ", " << value.d << ", "
     << value.tx << ", " << value.ty << ")";
  return ss.str();
}

template<>
std::string FormatValue(CGAffineTransform *value) {
  return FormatValue(*value);
}

template<>
std::string FormatValue(const CGPoint value) {
  std::stringstream ss;
  ss << "(" << value.x << ", " << value.y << ")";
  return ss.str();
}

template<>
std::string FormatValue(const CGRect value) {
  std::stringstream ss;
  ss << "(" << value.origin.x << ", " << value.origin.y << ", "
     << value.size.width << ", " << value.size.height << ")";
  return ss.str();
}

template<>
std::string FormatValue(CGLineCap value) {
  switch (value) {
    case kCGLineCapButt:
      return "kCGLineCapButt";
    case kCGLineCapRound:
      return "kCGLineCapRound";
    case kCGLineCapSquare:
      return "kCGLineCapSquare";
  }
}

template<>
std::string FormatValue(CGLineJoin value) {
  switch (value) {
    case kCGLineJoinMiter:
      return "kCGLineJoinMiter";
    case kCGLineJoinRound:
      return "kCGLineJoinRound";
    case kCGLineJoinBevel:
      return "kCGLineJoinBevel";
  }
}

}  // namespace internal
}  // namespace metrosvg
