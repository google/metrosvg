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

#include "MetroSVG/Internal/StyleSheet.h"
#include "MetroSVG/Internal/Utils.h"

#define SVGAssertCSSProperty(__pair, __name, __value) \
  do {\
    XCTAssertEqual(__pair.first, __name); \
    XCTAssertEqual(__pair.second, __value); \
  } while (0)

using namespace metrosvg::internal;

@interface StyleSheetTest : XCTestCase
@end

@implementation StyleSheetTest

- (void)testParseStyleSheetData_OneProperty {
  const char *data = ".test1 { fill: red; }";
  std::unique_ptr<MSCStyleSheet>
      style_sheet(ParseStyleSheetData(data, strlen(data)));
  const std::vector<std::pair<std::string, std::string>> *value =
      FindValueOrNull(style_sheet->entry, std::string("test1"));
  XCTAssertTrue(value != NULL);
  XCTAssertEqual(value->size(), 1U);
  SVGAssertCSSProperty((*value)[0], "fill", "red");
}

- (void)testParseStyleSheetData_MultipleProperties {
  const char *data = ".test2{ fill:red; stroke:green; }";
  std::unique_ptr<MSCStyleSheet>
      style_sheet(ParseStyleSheetData(data, strlen(data)));
  const std::vector<std::pair<std::string, std::string>> *value =
      FindValueOrNull(style_sheet->entry, std::string("test2"));
  XCTAssertTrue(value != NULL);
  XCTAssertEqual(value->size(), 2U);
  SVGAssertCSSProperty((*value)[0], "fill", "red");
  SVGAssertCSSProperty((*value)[1], "stroke", "green");
}

- (void)testParseStyleSheetData_MultipleSelectors {
  const char *data = ".test3 { fill: red; } .test4 { stroke:green; }";
  std::unique_ptr<MSCStyleSheet>
      style_sheet(ParseStyleSheetData(data, strlen(data)));
  const std::vector<std::pair<std::string, std::string>> *value =
      FindValueOrNull(style_sheet->entry, std::string("test3"));
  XCTAssertTrue(value != NULL);
  XCTAssertEqual(value->size(), 1U);
  SVGAssertCSSProperty((*value)[0], "fill", "red");
  value = FindValueOrNull(style_sheet->entry, std::string("test4"));
  XCTAssertEqual(value->size(), 1U);
  SVGAssertCSSProperty((*value)[0], "stroke", "green");
}

- (void)testParseStyleSheetData_ErrorInvalidSelector1 {
  const char *data = ".te st5 { fill: red; }";
  std::unique_ptr<MSCStyleSheet>
      style_sheet(ParseStyleSheetData(data, strlen(data)));
  XCTAssertTrue(style_sheet == NULL);
}

- (void)testParseStyleSheetData_ErrorInvalidSelector2 {
  const char *data = "rect  .test6 { fill: red; }";
  std::unique_ptr<MSCStyleSheet>
      style_sheet(ParseStyleSheetData(data, strlen(data)));
  XCTAssertTrue(style_sheet == NULL);
}

- (void)testSVGCSSMerge_SameSelector {
  const char *data_dest = ".test9 { fill:red; }";
  std::unique_ptr<MSCStyleSheet>
      dest(ParseStyleSheetData(data_dest, strlen(data_dest)));
  const char *data_source = ".test9 { fill:green; }";
  std::unique_ptr<MSCStyleSheet>
      source(ParseStyleSheetData(data_source, strlen(data_source)));
  MSCStyleSheetMerge(*source.get(), dest.get());
  const std::vector<std::pair<std::string, std::string>> *value =
      FindValueOrNull(dest->entry, std::string("test9"));
  XCTAssertTrue(value != NULL);
  XCTAssertEqual(value->size(), 2U);
  SVGAssertCSSProperty((*value)[0], "fill", "red");
  SVGAssertCSSProperty((*value)[1], "fill", "green");
}

- (void)testSVGCSSMerge_DifferentSelectors {
  const char *data_dest = ".test10 { fill:red; }";
  std::unique_ptr<MSCStyleSheet>
      desct(ParseStyleSheetData(data_dest, strlen(data_dest)));
  const char *data_source = ".test11 { fill:green; }";
  std::unique_ptr<MSCStyleSheet>
      source(ParseStyleSheetData(data_source, strlen(data_source)));
  MSCStyleSheetMerge(*source.get(), desct.get());
  const std::vector<std::pair<std::string, std::string>> *value =
      FindValueOrNull(desct->entry, std::string("test10"));
  XCTAssertTrue(value != NULL);
  XCTAssertEqual(value->size(), 1U);
  SVGAssertCSSProperty((*value)[0], "fill", "red");
  value = FindValueOrNull(desct->entry, std::string("test11"));
  XCTAssertEqual(value->size(), 1U);
  SVGAssertCSSProperty((*value)[0], "fill", "green");
}

- (void)testSVGCSSMerge_MultipleSourceSelectors {
  const char *data_dest = ".test12 { fill:red; }";
  std::unique_ptr<MSCStyleSheet>
      dest(ParseStyleSheetData(data_dest, strlen(data_dest)));
  const char *data_source = ".test13 { fill: red; } .test14 { stroke:green; }";
  std::unique_ptr<MSCStyleSheet>
      source(ParseStyleSheetData(data_source, strlen(data_source)));
  MSCStyleSheetMerge(*source.get(), dest.get());
  const std::vector<std::pair<std::string, std::string>> *value =
      FindValueOrNull(dest->entry, std::string("test12"));
  XCTAssertTrue(value != NULL);
  XCTAssertEqual(value->size(), 1U);
  SVGAssertCSSProperty((*value)[0], "fill", "red");
  value = FindValueOrNull(dest->entry, std::string("test13"));
  XCTAssertEqual(value->size(), 1U);
  SVGAssertCSSProperty((*value)[0], "fill", "red");
  value = FindValueOrNull(dest->entry, std::string("test14"));
  XCTAssertEqual(value->size(), 1U);
  SVGAssertCSSProperty((*value)[0], "stroke", "green");
}

- (void)testSVGCSSMerge_MultipleSourceProperties {
  const char *data_dest = ".test15 { fill:red; }";
  std::unique_ptr<MSCStyleSheet>
      dest(ParseStyleSheetData(data_dest, strlen(data_dest)));
  const char *data_source = ".test15 { fill: red; stroke:green; }";
  std::unique_ptr<MSCStyleSheet>
      source(ParseStyleSheetData(data_source, strlen(data_source)));
  MSCStyleSheetMerge(*source.get(), dest.get());
  const std::vector<std::pair<std::string, std::string>> *value =
      FindValueOrNull(dest->entry, std::string("test15"));
  XCTAssertTrue(value != NULL);
  XCTAssertEqual(value->size(), 3U);
  SVGAssertCSSProperty((*value)[0], "fill", "red");
  SVGAssertCSSProperty((*value)[1], "fill", "red");
  SVGAssertCSSProperty((*value)[2], "stroke", "green");
}

@end
