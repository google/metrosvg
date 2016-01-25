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

#include "MetroSVG/Public/MSCStylesheet.h"

#if defined __cplusplus
extern "C" {
#endif

// MSCDocument is an opaque type that represents a single SVG document.
typedef struct MSCDocument MSCDocument;

// Creates an MSCDocument instance with UTF-8-encoded SVG data. The data will be
// partially parsed to compute basic properties of the image. The returned
// instance must be deleted with MSCDocumentDelete when it is done.
// |url| can be NULL.
MSCDocument *MSCDocumentCreateFromData(const char *data,
                                       size_t length,
                                       const char *url);

// Deletes an MSCDocument instance.
void MSCDocumentDelete(MSCDocument *document);

// Fully parses data in a given MSCDocument and creates a CGImage from it.
// The caller is responsible for releasing the returned object.
// |style_sheet| can be NULL.
CGImageRef MSCDocumentCreateCGImage(MSCDocument *document,
                                    CGSize canvas_size,
                                    const MSCStyleSheet *style_sheet);

// Returns the image's intrinsic size as defined by "width" and "height"
// attributes of the outermost svg element. If these attributes are not
// specified, zero is assumed.
CGSize MSCDocumentGetImageSize(const MSCDocument *document);

// Returns value of "viewBox" attribute of the outermost svg element. Returns
// CGRectNull if the attribute is not specified.
CGRect MSCDocumentGetImageViewBox(const MSCDocument *document);

#if defined __cplusplus
}  // extern "C"
#endif
