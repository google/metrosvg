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

#include "MetroSVG/Internal/StringPiece.h"

using namespace metrosvg::internal;

@interface StringPieceTest : XCTestCase
@end

@implementation StringPieceTest

- (void)testEqualsOperator_Char {
  StringPiece lhs("abc");
  XCTAssertTrue(lhs == "abc");
  XCTAssertFalse(lhs == "ab");
  XCTAssertFalse(lhs == "abcd");
  XCTAssertFalse(lhs == "abe");
  XCTAssertFalse(lhs == "");
  XCTAssertFalse(lhs == NULL);
}

- (void)testFind_Char {
  StringPiece s("abcabc");
  XCTAssertEqual(s.find('a'), size_t(0));
  XCTAssertEqual(s.find('b'), size_t(1));
  XCTAssertEqual(s.find('c'), size_t(2));
  XCTAssertEqual(s.find('d'), std::string::npos);
}

- (void)testFind_Char_EmptyTarget {
  StringPiece s;
  XCTAssertEqual(s.find('a'), std::string::npos);
}

- (void)testFind_StdString {
  StringPiece s("abcdabcd");
  XCTAssertEqual(s.find("ab"), size_t(0));
  XCTAssertEqual(s.find("bc"), size_t(1));
  XCTAssertEqual(s.find("cd"), size_t(2));
  XCTAssertEqual(s.find("de"), std::string::npos);
}

- (void)testFind_StdString_EmptyTarget {
  StringPiece s;
  XCTAssertEqual(s.find("ab"), std::string::npos);
}

@end
