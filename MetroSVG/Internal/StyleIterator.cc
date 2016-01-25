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

#include "MetroSVG/Internal/StyleIterator.h"

#include "MetroSVG/Internal/BasicValueParsers.h"

namespace metrosvg {
namespace internal {

StyleIterator::StyleIterator(
    StringPiece *s,
    const std::unordered_set<std::string> &supported_properties)
  : s_(s),
    supported_properties_(supported_properties) {}

bool StyleIterator::Next() {
  ConsumeWhitespace(s_);
  if (s_->length() == 0) {
    return false;
  }
  size_t pos = s_->find(':');
  if (pos == std::string::npos) {
    // TODO: throw exception
    return false;
  }
  property_ = TrimTrailingWhitespace(StringPiece(s_->begin(), pos));
  s_->Advance(pos + 1);

  ConsumeWhitespace(s_);
  pos = s_->find(';');
  if (pos == std::string::npos) {
    value_ = TrimTrailingWhitespace(*s_);
    s_->Advance(s_->length());
  } else {
    value_ = TrimTrailingWhitespace(StringPiece(s_->begin(), pos));
    s_->Advance(pos + 1);
  }

  if (supported_properties_.count(property_.as_std_string())) {
    return true;
  }
  return Next();
}

}  // namespace internal
}  // namespace metrosvg
