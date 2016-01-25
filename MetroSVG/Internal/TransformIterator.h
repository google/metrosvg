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

namespace metrosvg {
namespace internal {

class StringPiece;

class TransformIterator {
 public:
  explicit TransformIterator(StringPiece *s);

  bool Next();
  const CGAffineTransform &transform() const { return transform_; }

 private:
  void ConsumeTransformDelimeters(StringPiece *s) const;

  StringPiece *s_;
  CGAffineTransform transform_;
  bool is_first;
};

}  // namespace internal
}  // namespace metrosvg
