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

#include "MetroSVG/Internal/StringPiece.h"

#include <algorithm>

namespace metrosvg {
namespace internal {

const std::string StringPiece::as_std_string() const {
  return std::string(begin_, length_);
}

void StringPiece::Advance(size_t n) {
  begin_ = begin_ + std::min(n, length_);
  length_ = length_ - std::min(n, length_);
}

size_t StringPiece::find(char c) const {
  const char *iter = std::find(begin_, end(), c);
  if (iter == end()) {
    return std::string::npos;
  } else {
    return iter - begin_;
  }
}

size_t StringPiece::find(const StringPiece &s) const {
  const char * pos = std::search(begin_, end(), s.begin_, s.end());
  if (pos == end()) {
    return std::string::npos;
  } else {
    return pos - begin_;
  }
}

}  // namespace internal
}  // namespace metrosvg
