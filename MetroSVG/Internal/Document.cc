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

#include "MetroSVG/Internal/Document.h"

#include "MetroSVG/Internal/BasicValueParsers.h"
#include "MetroSVG/Internal/Renderer.h"
#include "MetroSVG/Internal/StringPiece.h"
#include "MetroSVG/Internal/Utils.h"

namespace metrosvg {
namespace internal {

// Get size of the outmost svg element in given svg data.
bool GetImageMetaDataFromSVGData(const char *data,
                                 size_t data_length,
                                 CGSize *image_size,
                                 CGRect *view_box) {
  // Defaults to 100% per spec but we don't support length units yet.
  // http://www.w3.org/TR/SVG/struct.html#SVGElementWidthAttribute
  Length width(100.f, Length::kUnitNone);
  Length height(100.f, Length::kUnitNone);

  xmlTextReader *reader =
      xmlReaderForMemory(data, static_cast<int>(data_length), NULL, NULL, 0);
  bool success = true;
  int last_xml_status;
  while ((last_xml_status = xmlTextReaderRead(reader)) > 0) {
    int node_type = xmlTextReaderNodeType(reader);
    StringPiece elem_name =
        reinterpret_cast<const char *>(xmlTextReaderConstName(reader));
    if (node_type == XML_READER_TYPE_ELEMENT && elem_name == "svg") {
      while (xmlTextReaderMoveToNextAttribute(reader)) {
        StringPiece attr_name =
            reinterpret_cast<const char *>(xmlTextReaderConstName(reader));
        StringPiece attr_value =
            reinterpret_cast<const char *>(xmlTextReaderConstValue(reader));
        if (attr_name == "width") {
          if (!ParseLength(attr_value, &width)) {
            success = false;
          }
        } else if (attr_name == "height") {
          if (!ParseLength(attr_value, &height)) {
            success = false;
          }
        } else if (attr_name == "viewBox") {
          CGFloat values[4] = {0, 0, 0, 0};
          if (ParseFloats(attr_value, 4, values)) {
            *view_box =
                CGRectMake(values[0], values[1], values[2], values[3]);
          }
        }
      }
      break;
    }
  }
  xmlFreeTextReader(reader);

  if (last_xml_status < 0) {
    success = false;
  }

  if (success) {
    *image_size = CGSizeMake(width.value, height.value);
    return true;
  } else {
    return false;
  }
}

}  // namespace internal
}  // namespace metrosvg

using metrosvg::internal::GetImageMetaDataFromSVGData;
using metrosvg::internal::Renderer;

MSCDocument *MSCDocumentCreateFromData(const char *data,
                                       size_t length,
                                       const char *url) {
  CGSize size = CGSizeZero;
  CGRect view_box = CGRectNull;
  if (!GetImageMetaDataFromSVGData(data, length, &size, &view_box)) {
    return NULL;
  }

  MSCDocument *document = new MSCDocument;
  document->data = data;
  document->data_length = length;
  document->url = url;
  document->size = size;
  document->view_box = view_box;
  return document;
}

void MSCDocumentDelete(MSCDocument *document) {
  delete document;
}

CGImageRef MSCDocumentCreateCGImage(MSCDocument *document,
                                    CGSize canvas_size,
                                    const MSCStyleSheet *style_sheet) {
  Renderer renderer;
  return renderer.CreateCGImageFromMSCDocument(document,
                                               canvas_size,
                                               style_sheet);
}

CGSize MSCDocumentGetImageSize(const MSCDocument *document) {
  return document->size;
}

CGRect MSCDocumentGetImageViewBox(const MSCDocument *document) {
  return document->view_box;
}
