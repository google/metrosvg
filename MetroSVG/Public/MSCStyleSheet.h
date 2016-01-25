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

#if defined __cplusplus
extern "C" {
#endif

// MSCStyleSheet is an opaque type that represents a set of CSS rules.
typedef struct MSCStyleSheet MSCStyleSheet;

// Creates an MSCStyleSheet instance with UTF-8-encoded CSS data. The instance
// must be deleted with MSCStyleSheetDelete when it is done.
MSCStyleSheet *MSCStyleSheetCreateWithData(const char *data, size_t length);

// Delets an MSCStyleSheet instance.
void MSCStyleSheetDelete(MSCStyleSheet *style_sheet);

#if defined __cplusplus
}  // extern "C"
#endif
