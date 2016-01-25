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

#include <unordered_set>

#include "MetroSVG/Internal/StringPiece.h"

namespace metrosvg {
namespace internal {

class StyleIterator {
 public:
  StyleIterator(StringPiece *s,
                const std::unordered_set<std::string> &supported_properties);

  // Sets property and value to the next style in supported_properties.
  bool Next();
  const StringPiece &property() const { return property_; }
  const StringPiece &value() const { return value_; }

 private:
  StringPiece *s_;
  StringPiece property_;
  StringPiece value_;
  const std::unordered_set<std::string> supported_properties_;
};

}  // namespace internal
}  // namespace metrosvg
