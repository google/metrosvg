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

#import <XCTest/XCTest.h>

#include "MetroSVG/Internal/StyleIterator.h"

using namespace metrosvg::internal;

@interface StyleIteratorTest : XCTestCase
@end

@implementation StyleIteratorTest

- (void)test_Success_WithoutTrailingSemicolon {
  StyleIterator iter(new StringPiece("prop1:value1;prop2:value2"),
                     { std::string("prop1"), std::string("prop2") });
  XCTAssertTrue(iter.Next());
  XCTAssertTrue(iter.property() == "prop1");
  XCTAssertTrue(iter.value() == "value1",
                @"%s", iter.value().as_std_string().c_str());

  XCTAssertTrue(iter.Next());
  XCTAssertTrue(iter.property() == "prop2");
  XCTAssertTrue(iter.value() == "value2",
                @"%s", iter.value().as_std_string().c_str());

  XCTAssertFalse(iter.Next());
}

- (void)test_Success_WithTrailingSemicolon {
  StyleIterator iter(new StringPiece("prop1:value1;prop2:value2;"),
                     { std::string("prop1"), std::string("prop2") });
  XCTAssertTrue(iter.Next());
  XCTAssertTrue(iter.property() == "prop1");
  XCTAssertTrue(iter.value() == "value1", @"%s",
                iter.value().as_std_string().c_str());

  XCTAssertTrue(iter.Next());
  XCTAssertTrue(iter.property() == "prop2");
  XCTAssertTrue(iter.value() == "value2", @"%s",
                iter.value().as_std_string().c_str());

  XCTAssertFalse(iter.Next());
}

- (void)test_Success_Whitespace {
  StyleIterator iter(new StringPiece(" prop1 : value1 ; prop2 : value2 "),
                     { std::string("prop1"), std::string("prop2") });
  XCTAssertTrue(iter.Next());
  XCTAssertTrue(iter.property() == "prop1", @"%s was not equal to %s",
                iter.property().as_std_string().c_str(), "prop1");
  XCTAssertTrue(iter.value() == "value1", @"%s was not equal to %s",
                iter.value().as_std_string().c_str(), "value1");

  XCTAssertTrue(iter.Next());
  XCTAssertTrue(iter.property() == "prop2");
  XCTAssertTrue(iter.value() == "value2", @"%s",
                iter.value().as_std_string().c_str());

  XCTAssertFalse(iter.Next());
}

@end
