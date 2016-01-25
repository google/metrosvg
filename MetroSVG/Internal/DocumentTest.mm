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

#include <string>

#import <XCTest/XCTest.h>

#include "MetroSVG/Internal/Document.h"

@interface DocumentTest : XCTestCase
@end

@implementation DocumentTest

- (void)testGetImageAspectRatio {
  std::string data = "<svg viewBox=\"0 0 640 480\"></svg>";
  MSCDocument *document =
      MSCDocumentCreateFromData(data.c_str(), data.size(), "");
  XCTAssert(CGRectEqualToRect(MSCDocumentGetImageViewBox(document),
                              CGRectMake(0, 0, 640, 480)));
  MSCDocumentDelete(document);
}

- (void)testGetImageAspectRatio_ImplicitDefault {
  // TODO: What to do when viewBox is not specified?
}


// TODO: Write more tests of SVGDocument* public functions.

@end
