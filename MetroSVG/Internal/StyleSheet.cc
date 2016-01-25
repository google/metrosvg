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

#include "MetroSVG/Internal/StyleSheet.h"

#include "MetroSVG/Internal/StringPiece.h"
#include "MetroSVG/Internal/StyleIterator.h"

MSCStyleSheet *MSCStyleSheetCreateWithData(const char *data,
                                           size_t data_length) {
  return metrosvg::internal::ParseStyleSheetData(data, data_length);
}

void MSCStyleSheetDelete(MSCStyleSheet *style_sheet) {
  delete style_sheet;
}

namespace metrosvg {
namespace internal {

// ParserState is state for parsing CSS.
// At OUTSIDE_CONTENTS, before reading selector name and after reading "}".
// At BEFORE_VALUE, after reading selector name and before reading "{".
// At FINDING_VALUE, reading values between "{" and "}".
enum ParserState {
  OUTSIDE_CONTENTS,
  BEFORE_VALUE,
  FINDING_VALUE,
};

MSCStyleSheet *ParseStyleSheetData(const char *data,
                                   size_t data_length) {
  ParserState state = OUTSIDE_CONTENTS;
  std::string selector_name;
  std::string selector_value;
  std::vector<std::pair<std::string, std::string>> selector_data;
  std::unordered_set<std::string> supported_styles;
  supported_styles.insert("fill");
  supported_styles.insert("stop-color");
  supported_styles.insert("stroke");
  supported_styles.insert("stroke-width");
  std::unique_ptr<MSCStyleSheet> style_sheet(new MSCStyleSheet);

  for (size_t i = 0; i < data_length; i++) {
    switch (state) {
      case OUTSIDE_CONTENTS:
        switch (data[i]) {
          case '.':
            while (('a' <= data[i + 1] && data[i + 1] <= 'z') ||
                   ('A' <= data[i + 1] && data[i + 1] <= 'Z') ||
                   ('0' <= data[i + 1] && data[i + 1] <= '9') ||
                   data[i + 1] == '-' || data[i + 1] == '_') {
              selector_name += data[(i++) + 1];
            }
            state = BEFORE_VALUE;
            break;
          case '\n':
          case '\t':
          case ' ':
            break;
          default:
            return NULL;
        }
        break;
      case BEFORE_VALUE:
        switch (data[i]) {
          case '{':
            state = FINDING_VALUE;
            break;
          case ' ':
            break;
          default:
            return NULL;
        }
        break;
      case FINDING_VALUE:
        switch (data[i]) {
          case '}': {
            StringPiece sp = StringPiece(selector_value);
            StyleIterator style_iter(&sp, supported_styles);
            while (style_iter.Next()) {
              const std::string style_property =
                  style_iter.property().as_std_string();
              const std::string style_value =
                  style_iter.value().as_std_string();
              selector_data.push_back(std::pair<std::string,
                                      std::string>(style_property,
                                                   style_value));
            }
            style_sheet->entry.insert(std::make_pair(selector_name,
                                                     selector_data));
            selector_data.clear();
            selector_name = "";
            selector_value = "";
            state = OUTSIDE_CONTENTS;
            break;
          }
          case ' ':
          case '\n':
            break;
          default:
            selector_value += data[i];
            break;
        }
        break;
      }
  }
  return style_sheet.release();
}

void MSCStyleSheetMerge(const MSCStyleSheet &source,
                        MSCStyleSheet *dest) {
  if (dest == NULL) {
    return;
  }
  for (auto source_item : source.entry) {
    auto dest_item = dest->entry.find(source_item.first);
    if (dest_item == dest->entry.end()) {
      dest->entry.insert(source_item);
    } else {
      dest_item->second.insert(dest_item->second.end(),
                               source_item.second.begin(),
                               source_item.second.end());
    }
  }
}

}  // namespace internal
}  // namespace metrosvg
