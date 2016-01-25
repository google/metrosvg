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

#include <cstring>
#include <memory>
#include <string>

namespace metrosvg {
namespace internal {

class StringPiece {
 public:
  StringPiece()
     : begin_(NULL), length_(0) {}

  StringPiece(const char *s)
      : begin_(s), length_(s ? std::strlen(s) : 0) {}

  StringPiece(const std::string &s)
      : begin_(s.data()), length_(s.length()) {}

  StringPiece(const char *begin, size_t length)
      : begin_(begin), length_(length) {}

  StringPiece(const char *begin, const char *end)
      : begin_(begin), length_(end - begin) {}

  StringPiece(const StringPiece &rhs)
      : begin_(rhs.begin_), length_(rhs.length_) {}

  StringPiece &operator=(const StringPiece &rhs) {
    begin_ = rhs.begin_;
    length_ = rhs.length_;
    return *this;
  }

  bool operator==(const StringPiece &rhs) const {
    if (length() != rhs.length()) {
      return false;
    }
    for (size_t i = 0; i < length(); ++i) {
      if ((*this)[i] != rhs[i]) {
        return false;
      }
    }
    return true;
  }

  bool operator==(const char *rhs) const {
    return (*this) == StringPiece(rhs);
  }

  char operator[](size_t n) const { return *(begin_ + n); }

  const char *begin() const { return begin_; }
  const char *end() const { return begin_ + length_; }
  size_t length() const { return length_; }

  const std::string as_std_string() const;

  size_t find(char c) const;
  size_t find(const StringPiece &s) const;

  void Advance(size_t n);

 private:
  const char *begin_;
  size_t length_;
};

}  // namespace internal
}  // namespace metrosvg
