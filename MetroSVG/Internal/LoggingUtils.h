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

#include <cstddef>
#include <sstream>
#include <string>

#include <CoreGraphics/CoreGraphics.h>

namespace metrosvg {
namespace internal {

class LogArg;

std::string FormatArgs();
std::string FormatArgs(const LogArg &arg1);
std::string FormatArgs(const LogArg &arg1, const LogArg &arg2);
std::string FormatArgs(const LogArg &arg1, const LogArg &arg2,
                       const LogArg &arg3);
std::string FormatArgs(const LogArg &arg1, const LogArg &arg2,
                       const LogArg &arg3, const LogArg &arg4);
std::string FormatArgs(const LogArg &arg1, const LogArg &arg2,
                       const LogArg &arg3, const LogArg &arg4,
                       const LogArg &arg5);
std::string FormatArgs(const LogArg &arg1, const LogArg &arg2,
                       const LogArg &arg3, const LogArg &arg4,
                       const LogArg &arg5, const LogArg &arg6);
std::string FormatArgs(const LogArg &arg1, const LogArg &arg2,
                       const LogArg &arg3, const LogArg &arg4,
                       const LogArg &arg5, const LogArg &arg6,
                       const LogArg &arg7);

template<typename T>
std::string FormatValue(T value) {
  std::stringstream ss;
  ss << value;
  return ss.str();
}

template<>
std::string FormatValue(std::nullptr_t value);

template<>
std::string FormatValue(CGAffineTransform value);

template<>
std::string FormatValue(CGAffineTransform *value);

template<>
std::string FormatValue(CGPoint value);

template<>
std::string FormatValue(CGRect value);

template<>
std::string FormatValue(CGLineCap value);

template<>
std::string FormatValue(CGLineJoin value);

class LogArg {
 public:
  template<typename T>
  LogArg(const T &value)
      : string_value_(FormatValue(value)) {}

  std::string string_value() const {
    return string_value_;
  }

 private:
  std::string string_value_;
};

}  // namespace internal
}  // namespace metrosvg
