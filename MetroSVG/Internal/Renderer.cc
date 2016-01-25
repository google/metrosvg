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

#include "MetroSVG/Internal/Renderer.h"

#include <cmath>
#include <cstdio>
#include <cstring>
#include <iostream>
#include <string>

#include <CoreGraphics/CoreGraphics.h>
#include <libxml/xmlreader.h>

#include "MetroSVG/Internal/BasicValueParsers.h"
#include "MetroSVG/Internal/Constants.h"
#include "MetroSVG/Internal/Debug.h"
#include "MetroSVG/Internal/Document.h"
#include "MetroSVG/Internal/Gradient.h"
#include "MetroSVG/Internal/LoggingUtils.h"
#include "MetroSVG/Internal/Macros.h"
#include "MetroSVG/Internal/PathDataIterator.h"
#include "MetroSVG/Internal/StyleIterator.h"
#include "MetroSVG/Internal/StyleSheet.h"
#include "MetroSVG/Internal/TransformIterator.h"
#include "MetroSVG/Internal/Utils.h"

#ifndef SVG_LOG_CORE_GRAPHICS_CALLS
#define SVG_LOG_CORE_GRAPHICS_CALLS 0
#endif

namespace metrosvg {
namespace internal {

#define LOG_CGC_CALL(command, state_stack, ...) { \
  fprintf(stderr, \
          "<%s> (%d, %d) ", \
          state_stack.back().element_definition.name, \
          state_stack.back().element_line_number, \
          state_stack.back().element_column_number); \
  fprintf(stderr, \
          "CGContext%s(%s)\n", \
          command, \
          FormatArgs(__VA_ARGS__).c_str()); \
}

#define LOG_CGP_CALL(command, state_stack, ...) { \
  fprintf(stderr, \
          "<%s> (%d, %d) ", \
          state_stack.back().element_definition.name, \
          state_stack.back().element_line_number, \
          state_stack.back().element_column_number); \
  fprintf(stderr, \
          "CGPath%s(%s)\n", \
          command, \
          FormatArgs(__VA_ARGS__).c_str()); \
}

#if SVG_LOG_CORE_GRAPHICS_CALLS
#define CGC_CALL(command, state_stack, context, ...) { \
  if (GetCoreGraphicsCallLoggingEnabled()) { \
    LOG_CGC_CALL(#command, state_stack, ##__VA_ARGS__); \
  } \
  CGContext##command(context, ##__VA_ARGS__); \
}
#define CGP_CALL(command, state_stack, path, ...) { \
  if (GetCoreGraphicsCallLoggingEnabled()) { \
    LOG_CGP_CALL(#command, state_stack, ##__VA_ARGS__); \
  } \
  CGPath##command(path, ##__VA_ARGS__); \
}
#else
#define CGC_CALL(command, state_stack, context, ...) { \
  CGContext##command(context, ##__VA_ARGS__); \
}
#define CGP_CALL(command, state_stack, path, ...) { \
  CGPath##command(path, ##__VA_ARGS__); \
}
#endif

class ParseError {
 public:
  ParseError() {}
};

// kSvgElementRoot is a dummy element that means we haven't started
// reading an SVG file.
const Renderer::SVGElementDefinition Renderer::kSvgElementRoot = {
    "__ROOT__", NULL, NULL};

const Renderer::SVGElementDefinition Renderer::kSvgElementUnknown = {
    "__UNKNOWN__", NULL, NULL};

Renderer::Renderer()
    : supported_styles_({
        std::string("fill"),
        std::string("stop-color"),
        std::string("stroke"),
      }),
      graphics_(),
      svg_element_definitions_({
        {"circle",
          &Renderer::ProcessCircleElement,
          NULL},
        {"ellipse",
          &Renderer::ProcessEllipseElement,
          NULL},
        {"g",
          &Renderer::ProcessGElement,
          NULL},
        {"line",
          &Renderer::ProcessLineElement,
          NULL},
        {"linearGradient",
          &Renderer::BeginLinearGradientElement,
          &Renderer::EndLinearGradientElement},
        {"path", &Renderer::ProcessPathElement,
          NULL},
        {"polygon",
          &Renderer::ProcessPolygonElement,
          NULL},
        {"polyline",
          &Renderer::ProcessPolylineElement,
          NULL},
        {"radialGradient",
          &Renderer::BeginRadialGradientElement,
          &Renderer::EndRadialGradientElement},
        {"rect",
          &Renderer::ProcessRectElement,
          NULL},
        {"stop",
          &Renderer::ProcessStopElement,
          NULL},
        {"style",
          &Renderer::BeginStyleElement,
          &Renderer::EndStyleElement},
        {"svg",
          &Renderer::ProcessSvgElement,
          NULL},
      }) {
  state_stack_.emplace_back(kSvgElementRoot, 0, 0, graphics_);
}

Renderer::~Renderer() {
  for (std::pair<std::string, Gradient *> entry : gradients_) {
    delete entry.second;
  }
}

CGImageRef Renderer::CreateCGImageFromMSCDocument(MSCDocument *document,
                                                  CGSize canvas_size,
                                                  const MSCStyleSheet *style_sheet) {
  canvas_size_ = CGSizeMake(std::floor(canvas_size.width),
                            std::floor(canvas_size.height));
  if (document == NULL || canvas_size_.width < 1 || canvas_size_.height < 1) {
    return NULL;
  }

  if (style_sheet != NULL) {
    MergeStyleSheet(*style_sheet);
  }

  InitializeCGContext();
  auto delete_context = MakeUniquePtr(context_, CGContextRelease);

  int options = XML_PARSE_NOENT | XML_PARSE_NONET;
  reader_ = xmlReaderForMemory(document->data,
                               static_cast<int>(document->data_length),
                               document->url,
                               NULL,
                               options);
  auto delete_reader = MakeUniquePtr(reader_, xmlFreeTextReader);

  // SVG default.
  CGC_CALL(SetRGBFillColor, state_stack_, context_, 0.0, 0.0, 0.0, 1.0);
  try {
    int last_xml_status;
    while ((last_xml_status = xmlTextReaderRead(reader_)) > 0) {
      const char *name =
          reinterpret_cast<const char *>(xmlTextReaderConstName(reader_));
      bool isEmptyElement = xmlTextReaderIsEmptyElement(reader_);
      SVGElementDefinition element_definition = FindElementDefinition(name);
      int node_type = xmlTextReaderNodeType(reader_);
      if (node_type == XML_READER_TYPE_ELEMENT) {
        state_stack_.emplace_back(element_definition,
                                  xmlTextReaderGetParserLineNumber(reader_),
                                  xmlTextReaderGetParserColumnNumber(reader_),
                                  graphics_);
        CGC_CALL(SaveGState, state_stack_, context_);
        StringMap unprocessed_attributes;
        StringMap unprocessed_styles;
        if (!ProcessCommonAttributes(&unprocessed_attributes,
                                     &unprocessed_styles)) {
          return nullptr;
        }
        BeginElementHandler begin_handler = element_definition.begin_handler;
        if (begin_handler) {
          (this->*(begin_handler))(unprocessed_attributes, unprocessed_styles);
        }
      }

      if (node_type == XML_READER_TYPE_END_ELEMENT) {
        EndElementHandler end_handler =
            state_stack_.back().element_definition.end_handler;
        if (end_handler) {
          (this->*(end_handler))();
        }
      }

      if (node_type == XML_READER_TYPE_TEXT) {
        if (strcmp(state_stack_.back().element_definition.name, "style") == 0) {
          auto style_text =
              MakeUniquePtr(xmlTextReaderReadString(reader_), xmlFree);
          state_stack_.back().style_text_ =
              std::string(reinterpret_cast<const char *>(style_text.get()));
        }
      }

      if (node_type == XML_READER_TYPE_END_ELEMENT || isEmptyElement) {
        if (state_stack_.back().defines_transparency_layer) {
          CGC_CALL(EndTransparencyLayer, state_stack_, context_);
        }
        CGC_CALL(RestoreGState, state_stack_, context_);
        graphics_ = std::move(state_stack_.back().graphics);
        state_stack_.pop_back();
      }
    }
    if (last_xml_status < 0) {
      return nullptr;
    }
  } catch (const ParseError &e) {
    std::cerr << "Parse error";
  }

  CGImageRef image = CGBitmapContextCreateImage(context_);
  return image;
}

void Renderer::ProcessCircleElement(const StringMap &attributes,
                                    const StringMap &styles) {
  CGFloat cx = 0.0, cy = 0.0, r = 0.0;
  FloatValueForKey(attributes, std::string("cx"), &cx);
  FloatValueForKey(attributes, std::string("cy"), &cy);
  FloatValueForKey(attributes, std::string("r"), &r);
  if (r <= 0.0) {
    // TODO: Signal error if value is less than 0.
    return;
  }
  PaintElement([this, cx, cy, r] (CGContextRef context) {
    CGC_CALL(BeginPath, state_stack_, context);
    CGC_CALL(AddArc,
             state_stack_,
             context,
             cx,
             cy,
             r,
             CGFloat(0),
             CGFloat(2 * kPi),
             1);
    CGC_CALL(ClosePath, state_stack_, context);
  }, true);
}

void Renderer::ProcessEllipseElement(const StringMap &attributes,
                                     const StringMap &styles) {
  CGFloat cx = 0.0, cy = 0.0, rx = 0.0, ry = 0.0;
  FloatValueForKey(attributes, std::string("cx"), &cx);
  FloatValueForKey(attributes, std::string("cy"), &cy);
  FloatValueForKey(attributes, std::string("rx"), &rx);
  FloatValueForKey(attributes, std::string("ry"), &ry);
  if (rx <= 0.0 || ry <= 0.0) {
    // TODO: Signal error if value is less than 0.
    return;
  }
  PaintElement([this, cx, cy, rx, ry] (CGContextRef context) {
    CGC_CALL(BeginPath, state_stack_, context);
    CGRect ellipseBounds = CGRectMake(cx - rx, cy - ry, rx * 2, ry * 2);
    CGC_CALL(AddEllipseInRect, state_stack_, context, ellipseBounds);
    CGC_CALL(ClosePath, state_stack_, context);
  }, true);
}

void Renderer::ProcessGElement(const StringMap &attributes,
                               const StringMap &styles) {
  // We don't need any implementation for this because all required behavior
  // is handled by ProcessCommonAttributes.
}

void Renderer::ProcessLineElement(const StringMap &attributes,
                                  const StringMap &styles) {
  CGFloat x1 = 0.0, y1 = 0.0, x2 = 0.0, y2 = 0.0;
  FloatValueForKey(attributes, std::string("x1"), &x1);
  FloatValueForKey(attributes, std::string("y1"), &y1);
  FloatValueForKey(attributes, std::string("x2"), &x2);
  FloatValueForKey(attributes, std::string("y2"), &y2);
  PaintElement([this, x1, y1, x2, y2] (CGContextRef context) {
    CGC_CALL(BeginPath, state_stack_, context);
    CGC_CALL(MoveToPoint, state_stack_, context, x1, y1);
    CGC_CALL(AddLineToPoint, state_stack_, context, x2, y2);
  }, true);
}

void Renderer::BeginLinearGradientElement(const StringMap &attributes,
                                          const StringMap &styles) {
  pending_gradient_.reset(new Gradient(Gradient::kTypeLinear, attributes));
  Gradient::Linear *linear_gradient = &pending_gradient_->linear;

  Length x1(0, Length::kUnitPercent);
  LengthValueForKey(attributes, std::string("x1"), &x1);
  linear_gradient->x1 = x1;

  Length y1(0, Length::kUnitPercent);
  LengthValueForKey(attributes, std::string("y1"), &y1);
  linear_gradient->y1 = y1;

  Length x2(100, Length::kUnitPercent);
  LengthValueForKey(attributes, std::string("x2"), &x2);
  linear_gradient->x2 = x2;

  Length y2(0, Length::kUnitPercent);
  LengthValueForKey(attributes, std::string("y2"), &y2);
  linear_gradient->y2 = y2;
}

void Renderer::EndLinearGradientElement() {
  std::string id = pending_gradient_->id;
  // TODO: empty/duplicate check for id.
  gradients_[id] = pending_gradient_.release();
}

void Renderer::BeginRadialGradientElement(const StringMap &attributes,
                                          const StringMap &styles) {
  pending_gradient_.reset(new Gradient(Gradient::kTypeRadial, attributes));
  Gradient::Radial *radial_gradient = &pending_gradient_->radial;

  Length cx(50, Length::kUnitPercent);
  LengthValueForKey(attributes, std::string("cx"), &cx);
  radial_gradient->cx = cx;

  Length cy(50, Length::kUnitPercent);
  LengthValueForKey(attributes, std::string("cy"), &cy);
  radial_gradient->cy = cy;

  Length r(50, Length::kUnitPercent);
  LengthValueForKey(attributes, std::string("r"), &r);
  radial_gradient->r = r;

  Length fx = cx;
  LengthValueForKey(attributes, std::string("fx"), &fx);
  radial_gradient->fx = fx;

  Length fy = cy;
  LengthValueForKey(attributes, std::string("fy"), &fy);
  radial_gradient->fy = fy;
}

void Renderer::EndRadialGradientElement() {
  std::string id = pending_gradient_->id;
  // TODO: empty/duplicate check for id.
  gradients_[id] = pending_gradient_.release();
}

void Renderer::ProcessPathElement(const StringMap &attributes,
                                  const StringMap &styles) {
  const std::string *d_value = FindValueOrNull(attributes, std::string("d"));
  if (!d_value) {
    return;
  }
  PaintElement([this, d_value] (CGContextRef context) {
    PathDataIterator iterator(d_value->data(), kPathDataFormatPath, false);
    ProcessPathData(&iterator);
  }, true);
}

void Renderer::ProcessPolygonElement(const StringMap &attributes,
                                     const StringMap &styles) {
  PaintPolyElement(attributes, true);
}

void Renderer::ProcessPolylineElement(const StringMap &attributes,
                                      const StringMap &styles) {
  PaintPolyElement(attributes, false);
}

void Renderer::ProcessRectElement(const StringMap &attributes,
                                  const StringMap &styles) {
  CGFloat x = 0.0, y = 0.0;
  FloatValueForKey(attributes, std::string("x"), &x);
  FloatValueForKey(attributes, std::string("y"), &y);

  CGFloat width = 0.0, height = 0.0;
  FloatValueForKey(attributes, std::string("width"), &width);
  FloatValueForKey(attributes, std::string("height"), &height);
  if (width <= 0.0 || height <= 0.0) {
    return;
  }

  CGFloat rx = 0.0, ry = 0.0;
  bool has_valid_rx = FloatValueForKey(attributes, std::string("rx"), &rx);
  bool has_valid_ry = FloatValueForKey(attributes, std::string("ry"), &ry);
  if (rx < 0.0 || ry < 0.0) {
    return;
  }
  if (has_valid_rx && !has_valid_ry) {
    ry = rx;
  } else if (!has_valid_rx && has_valid_ry) {
    rx = ry;
  }
  if (rx > width / 2) {
    rx = width / 2;
  }
  if (ry > height / 2) {
    ry = height / 2;
  }

  CGRect rect = CGRectMake(x, y, width, height);
  PaintElement([this, rect, rx, ry] (CGContextRef context) {
    CGC_CALL(BeginPath, state_stack_, context);
    CGMutablePathRef path = CGPathCreateMutable();
    CGP_CALL(AddRoundedRect, state_stack_, path, NULL, rect, rx, ry);
    CGC_CALL(AddPath, state_stack_, context_, path);
    CGP_CALL(Release, state_stack_, path);
    CGC_CALL(ClosePath, state_stack_, context);
  }, true);
}

void Renderer::ProcessStopElement(const StringMap &attributes,
                                  const StringMap &styles) {
  if (!pending_gradient_) {
    // TODO: Signal error.
    return;
  }

  Length offset_length;
  if (!LengthValueForKey(attributes, std::string("offset"), &offset_length)) {
    // TODO: Signal error.
    return;
  }
  CGFloat offset;
  if (offset_length.unit == Length::kUnitNone) {
    offset = ClampToUnitRange(offset_length.value);
  } else if (offset_length.unit == Length::kUnitPercent) {
    offset = ClampToUnitRange(offset_length.value / 100);
  } else {
    return;
  }

  CGFloat last_offset = 0.f;
  if (pending_gradient_->stops.size() > 0) {
    last_offset = pending_gradient_->stops.back().offset;
  }
  if (offset < last_offset) {
    offset = last_offset;
  }
  pending_gradient_->stops.emplace_back(offset, graphics_.stop_color,
                                        graphics_.stop_opacity);
}

void Renderer::BeginStyleElement(const StringMap &attributes,
                                 const StringMap &styles) {
  const std::string *style_type =
      FindValueOrNull(attributes, std::string("type"));
  if (style_type != NULL) {
    state_stack_.back().style_type_ = *style_type;
  }
}

void Renderer::EndStyleElement() {
  if (state_stack_.back().style_type_ == "text/css") {
    const char *data = state_stack_.back().style_text_.c_str();
    size_t data_length = state_stack_.back().style_text_.length();
    std::unique_ptr<MSCStyleSheet> style_sheet(
        ParseStyleSheetData(data, data_length));
    if (style_sheet) {
      MergeStyleSheet(*style_sheet);
    }
  }
}

void Renderer::ProcessSvgElement(const StringMap &attributes,
                                 const StringMap &styles) {
  // First, parse width and height of this element. These values are
  // used later for different purposes.
  // TODO: Parse x and y too.
  Length width;
  const std::string *width_str =
      FindValueOrNull(attributes, std::string("width"));
  if (width_str) {
    if (!ParseLength(*width_str, &width) || width.value < 0) {
      return;  // TODO: Signal error.
    }
    if (width.value == 0) {
      return;  // TODO: Disable rendering per spec.
    }
  } else {
    width = Length(100, Length::kUnitPercent);
  }

  Length height;
  const std::string *height_str =
      FindValueOrNull(attributes, std::string("height"));
  if (height_str) {
    if (!ParseLength(*height_str, &height) || height.value < 0) {
      return;  // TODO: Signal error.
    }
    if (height.value == 0) {
      return;  // TODO: Disable rendering per spec.
    }
  } else {
    height = Length(100, Length::kUnitPercent);
  }

  // Calculate the new viewport that this svg element defines.
  CGRect new_viewport;
  bool is_outmost_svg_element = (state_stack_.size() == 2);
  if (is_outmost_svg_element) {
    // The outmost svg element is given a special treatment; we respect the
    // canvas size that the client has determined based on the intrinsic size
    // or aspect ratio of an image. The canvas specified by the client is the
    // viewport.
    new_viewport = CGRectMake(0, 0, canvas_size_.width, canvas_size_.height);

  } else {
    // TODO: Handle length units.
    new_viewport = CGRectMake(0, 0, width.value, height.value);
  }

  // Drawing of descendent elements should be cliped to this
  // new viewport.
  CGC_CALL(ClipToRect, state_stack_, context_, new_viewport);

  // Establish a new coordinate system if
  // - viewBox is specified, or
  // - this is the oustmost SVG element. In this case, we always need to
  //   establish a new coordinate system becaues the client can specify
  //   arbitrary canvas size.
  bool has_view_box = false;
  CGRect view_box = CGRectNull;
  const std::string *viewbox_str =
      FindValueOrNull(attributes, std::string("viewBox"));
  CGFloat values[4];
  if (viewbox_str && ParseFloats(*viewbox_str, 4, values)) {
    view_box = CGRectMake(values[0], values[1], values[2], values[3]);
    has_view_box = true;
  }
  if (!has_view_box && is_outmost_svg_element) {
    view_box = CGRectMake(0, 0, width.value, height.value);
    has_view_box = true;
  }
  if (has_view_box) {
    // Parse preserveAspectRatio. It only applies when viewBox is provided.
    bool parsed_aspect_ratio = false;
    PreserveAspectRatio aspect_ratio;
    const std::string *aspect_ratio_str =
        FindValueOrNull(attributes, std::string("preserveAspectRatio"));
    if (aspect_ratio_str) {
      parsed_aspect_ratio =
          ParsePreserveAspectRatio(*aspect_ratio_str, &aspect_ratio);
    }
    if (!parsed_aspect_ratio) {
      aspect_ratio = PreserveAspectRatio::default_value();
    }

    CGAffineTransform transform =
        CGAffineTransformForPreserveAspectRatio(
            aspect_ratio, view_box, new_viewport);
    CGC_CALL(ConcatCTM, state_stack_, context_, transform);
  }
}

void Renderer::ProcessFillOrStrokeValue(const std::string &value,
                                        bool is_fill) {
  RgbColor rgb;
  StringPiece iri;
  PaintState *paint_state = is_fill ? &graphics_.fill : &graphics_.stroke;

  if (value == "none") {
    paint_state->set_should_paint(false);
  } else if (ParseRgbColor(StringPiece(value), &rgb)) {
    paint_state->set_color(rgb);
    CallCGSetColor(is_fill);
  } else if (ParseIri(StringPiece(value), &iri)) {
    paint_state->set_iri(iri.as_std_string());
  }
}

void Renderer::CallCGSetColor(bool is_fill) {
  PaintState &paint_state = is_fill ? graphics_.fill : graphics_.stroke;
  const RgbColor &color = paint_state.color;
  if (is_fill) {
    CGC_CALL(SetRGBFillColor, state_stack_, context_,
             color.red(), color.green(), color.blue(),
             paint_state.opacity);
  } else {
    CGC_CALL(SetRGBStrokeColor, state_stack_, context_,
             color.red(), color.green(), color.blue(),
             paint_state.opacity);
  }
}

bool Renderer::ProcessStyle(const std::string &name,
                            const std::string &value) {
  RgbColor rgb;
  StringPiece iri;

  if (name == "fill") {
    ProcessFillOrStrokeValue(value, true);
  } else if (name == "stroke") {
    ProcessFillOrStrokeValue(value, false);
  } else if (name == "stroke-linecap") {
    CGLineCap lineCap;

    if (value == "butt") {
      lineCap = kCGLineCapButt;
    } else if (value == "round") {
      lineCap = kCGLineCapRound;
    } else if (value == "square") {
      lineCap = kCGLineCapSquare;
    } else {
      // Other values have no effect.
      return true;
    }
    CGC_CALL(SetLineCap, state_stack_, context_, lineCap);
  } else if (name == "stroke-linejoin") {
    CGLineJoin lineJoin;
    if (value == "miter") {
      lineJoin = kCGLineJoinMiter;
    } else if (value == "round") {
      lineJoin = kCGLineJoinRound;
    } else if (value == "bevel") {
      lineJoin = kCGLineJoinBevel;
    } else {
      // Other values have no effect.
      return true;
    }
    CGC_CALL(SetLineJoin, state_stack_, context_, lineJoin);
  } else if (name == "stroke-miterlimit") {
    CGFloat miterLimit;
    if (!metrosvg::internal::ParseFloat(StringPiece(value), &miterLimit)) {
      // TODO: Report an error.
      return true;
    }
    CGC_CALL(SetMiterLimit, state_stack_, context_, miterLimit);
  } else if (name == "stroke-width") {
    CGFloat strokeWidth;
    if (!metrosvg::internal::ParseFloat(StringPiece(value), &strokeWidth)) {
      // TODO: Report an error.
      return true;
    }
    CGC_CALL(SetLineWidth, state_stack_, context_, strokeWidth);
  } else if (name == "fill-opacity") {
    CGFloat opacity;
    if (!ParseFloat(StringPiece(value), &opacity)) {
      // TODO: throw an exception.
      return true;
    }
    graphics_.fill.ApplyOpacity(ClampToUnitRange(opacity));
    CallCGSetColor(true);
  } else if (name == "stroke-opacity") {
    CGFloat opacity;
    if (!ParseFloat(StringPiece(value), &opacity)) {
      // TODO: throw an exception.
      return true;
    }
    graphics_.stroke.ApplyOpacity(ClampToUnitRange(opacity));
    CallCGSetColor(false);
  } else if (name == "stop-color") {
    RgbColor color;
    if (ParseRgbColor(value, &color)) {
      graphics_.stop_color = color;
    }
  } else if (name == "stop-opacity") {
    CGFloat opacity = 1.0;
    if (ParseFloat(value, &opacity)) {
      graphics_.stop_opacity = ClampToUnitRange(opacity);
    }
  } else {
    // Note: opacity is not currently supported.
    return false;
  }
  return true;
}

void Renderer::ProcessDisplayValue(const std::string &value) {
  if (value == "none") {
    graphics_.display = false;
  }
  // We do not explicitly process values other than none,
  // because a parent node with display=none makes all child
  // nodes invisible.  See SVG 1.1 Section 11.5.
}

void Renderer::ProcessVisibilityValue(const std::string &value) {
  if (value == "visible") {
    graphics_.visibility = true;
  } else if (value == "hidden" || value == "collapse") {
    graphics_.visibility = false;
  }
  // There is also an "inherit" value, which should do nothing.
}

void Renderer::ProcessOpacityValue(const std::string &value) {
  CGFloat opacity;
  if (ParseFloat(value, &opacity)) {
    // CGContextSetAlpha internally clips opacity value to [0.0, 1.0].
    CGC_CALL(SetAlpha, state_stack_, context_, opacity);
    CGC_CALL(BeginTransparencyLayer, state_stack_, context_, nullptr);
    state_stack_.back().defines_transparency_layer = true;
  }
}

void Renderer::ProcessFillRuleValue(const std::string &value) {
  if (value == "evenodd") {
    graphics_.fill_rule = kFillRuleEvenOdd;
  } else if (value == "nonzero") {
    graphics_.fill_rule = kFillRuleNonZero;
  }
}

void Renderer::ProcessDashArrayValue(const std::string &value) {
  std::vector<Length> lengths;
  if (ParseLengths(value, &lengths)) {
    std::vector<CGFloat> dash_values;
    bool has_non_zero_element = false;
    for (Length l : lengths) {
      dash_values.push_back(l.value);
      if (l.value != 0) {
        has_non_zero_element = true;
      }
    }
    if (has_non_zero_element) {
      CGC_CALL(SetLineDash, state_stack_, context_, graphics_.line_dash.phase,
               dash_values.data(), dash_values.size());
      graphics_.line_dash.dash_values = std::move(dash_values);
    } else {
      CGC_CALL(SetLineDash, state_stack_, context_, 0, nullptr, 0);
      graphics_.line_dash.dash_values.clear();
    }
  } else if (value == "none") {
    CGC_CALL(SetLineDash, state_stack_, context_, 0, nullptr, 0);
    graphics_.line_dash.dash_values.clear();
  }
}

void Renderer::ProcessDashOffsetValue(const std::string &value) {
  Length phase;
  if (ParseLength(value, &phase)) {
    LineDash *line_dash = &graphics_.line_dash;
    if (line_dash->dash_values.size() > 0) {
      CGC_CALL(SetLineDash, state_stack_, context_, phase.value,
               line_dash->dash_values.data(), line_dash->dash_values.size());
    }
    line_dash->phase = phase.value;
  }
}

bool Renderer::ProcessCommonAttributes(StringMap *unprocessed_attributes,
                                       StringMap *unprocessed_styles) {
  std::string class_attr_value;
  std::string style_attr_value;
  const std::vector<std::pair<std::string, std::string>> *class_data;

  while (true) {
    int xml_status = xmlTextReaderMoveToNextAttribute(reader_);
    if (xml_status == 0) {
      break;
    } else if (xml_status < 0) {
      return false;
    }

    std::string name =
        reinterpret_cast<const char *>(xmlTextReaderConstName(reader_));
    const char *raw_value =
        reinterpret_cast<const char *>(xmlTextReaderConstValue(reader_));
    if (!raw_value) {
      continue;
    }
    std::string value(raw_value);

    if (ProcessStyle(name, value)) {
      continue;
    } else if (name == "transform") {
      StringPiece transform_value(value);
      metrosvg::internal::TransformIterator iter(&transform_value);
      while (iter.Next()) {
        const CGAffineTransform &transform = iter.transform();
        CGC_CALL(ConcatCTM, state_stack_, context_, transform);
      }
    } else if (name == "display") {
      ProcessDisplayValue(value);
    } else if (name == "visibility") {
      ProcessVisibilityValue(value);
    } else if (name == "opacity") {
      ProcessOpacityValue(value);
    } else if (name == "fill-rule") {
      ProcessFillRuleValue(value);
    } else if (name == "stroke-dasharray") {
      ProcessDashArrayValue(value);
    } else if (name == "stroke-dashoffset") {
      ProcessDashOffsetValue(value);
    } else if (name == "style") {
      style_attr_value = value;
    } else if (name == "class") {
      class_attr_value = value;
    } else {
      (*unprocessed_attributes)[name] = value;
    }
  }
  if (style_sheet_) {
    class_data = FindValueOrNull(style_sheet_->entry, class_attr_value);
    if (class_data != NULL) {
      for (size_t i = 0; i < class_data->size(); ++i) {
        ProcessStyle((*class_data)[i].first, (*class_data)[i].second);
      }
    }
  }
  if (style_attr_value != "") {
    StringPiece sp = StringPiece(style_attr_value);
    StyleIterator style_iter(&sp, supported_styles_);
    while (style_iter.Next()) {
      const std::string style_property =
          style_iter.property().as_std_string();
      const std::string style_value = style_iter.value().as_std_string();
      if (!ProcessStyle(style_property, style_value)) {
        (*unprocessed_styles)[style_property] = style_value;
      }
    }
  }
  return true;
}

void Renderer::ProcessPathData(PathDataIterator *iter) {
  CGMutablePathRef path = CGPathCreateMutable();
  while (iter->Next()) {
    bool success = true;
    switch (iter->command_type()) {
      case metrosvg::internal::kPathCommandTypeMoveTo:
        CGP_CALL(MoveToPoint,
                 state_stack_,
                 path,
                 NULL,
                 iter->point().x,
                 iter->point().y);
        break;
      case kPathCommandTypeLineTo:
      case kPathCommandTypeHorizontalLineTo:
      case kPathCommandTypeVerticalLineTo:
        CGP_CALL(AddLineToPoint,
                 state_stack_,
                 path,
                 NULL,
                 iter->point().x,
                 iter->point().y);
        break;
      case kPathCommandTypeCubicBezier:
      case kPathCommandTypeShorthandCubicBezier:
        CGP_CALL(AddCurveToPoint,
                 state_stack_,
                 path,
                 NULL,
                 iter->control_point1().x,
                 iter->control_point1().y,
                 iter->control_point2().x,
                 iter->control_point2().y,
                 iter->point().x,
                 iter->point().y);
        break;
      case kPathCommandTypeQuadBezier:
      case kPathCommandTypeShorthandQuadBezier:
        CGP_CALL(AddQuadCurveToPoint,
                 state_stack_,
                 path,
                 NULL,
                 iter->control_point1().x,
                 iter->control_point1().y,
                 iter->point().x,
                 iter->point().y);
        break;
      case kPathCommandTypeEllipticalArc:
        success = AddEllipticalArcToPath(*iter, &path);
        break;
      case kPathCommandTypeClosePath:
        CGP_CALL(CloseSubpath, state_stack_, path);
        break;
    }
    if (success == false) {
      break;
    }
  }
  CGC_CALL(AddPath,
           state_stack_,
           context_,
           path);
  CGP_CALL(Release, state_stack_, path);
}

bool Renderer::AddEllipticalArcToPath(const PathDataIterator &iter,
                                      CGMutablePathRef *path) {
  if (iter.command_type() != kPathCommandTypeEllipticalArc) {
    // TODO: Assert in debug build.
    return false;
  }
  CGAffineTransform transform_rotation1 =
      CGAffineTransformMakeRotation(-iter.rotation() * kPi / 180.f);
  CGAffineTransform transform_scale1
      = CGAffineTransformMakeScale(1 / iter.arc_radius_x(),
                                   1 / iter.arc_radius_y());
  CGAffineTransform transform1
      = CGAffineTransformConcat(transform_rotation1, transform_scale1);
  CGPoint previous_point
      = CGPointApplyAffineTransform(CGPathGetCurrentPoint(*path), transform1);
  CGPoint point = CGPointApplyAffineTransform(iter.point(),
                                              transform1);
  CGPoint center_point = CGPointZero;
  CGFloat start_angle = 0;
  CGFloat end_angle = 0;
  CGFloat radius = 1;
  if (SvgArcToCgArc(previous_point, point,
                    iter.large_arc(), iter.sweep(), &radius,
                    &center_point, &start_angle, &end_angle) == false) {
    return false;
  }
  CGAffineTransform transform2 = CGAffineTransformInvert(transform1);
  CGP_CALL(AddArc,
           state_stack_,
           *path,
           &transform2,
           center_point.x,
           center_point.y,
           radius,
           start_angle,
           end_angle,
           !iter.sweep());

  return true;
}

void Renderer::PaintPolyElement(const StringMap &attributes,
                                bool implicit_close) {
  const std::string *points = FindValueOrNull(attributes,
                                              std::string("points"));
  if (!points) {
    return;
  }
  PaintElement([this, points, implicit_close] (CGContextRef context) {
    CGC_CALL(BeginPath, state_stack_, context);
    PathDataIterator iterator(points->data(), kPathDataFormatPoints,
                              implicit_close);
    ProcessPathData(&iterator);
  }, true);
}

void Renderer::PaintElement(std::function<void(CGContextRef)> define_path,
                            bool is_fillable) {
  if (is_fillable && graphics_.fill.should_paint
      && graphics_.display && graphics_.visibility) {
    CGC_CALL(SaveGState, state_stack_, context_);
    define_path(context_);
    if (!graphics_.fill.iri.empty()) {
      DrawClippedGradient(graphics_.fill.iri);
    } else {
      if (graphics_.fill_rule == kFillRuleEvenOdd) {
        CGC_CALL(EOFillPath, state_stack_, context_);
      } else {
        CGC_CALL(FillPath, state_stack_, context_);
      }
    }
    CGC_CALL(RestoreGState, state_stack_, context_);
  }
  if (graphics_.stroke.should_paint
      && graphics_.display && graphics_.visibility) {
    CGC_CALL(SaveGState, state_stack_, context_);
    define_path(context_);
    if (!graphics_.stroke.iri.empty()) {
      CGC_CALL(ReplacePathWithStrokedPath, state_stack_, context_);
      DrawClippedGradient(graphics_.stroke.iri);
    } else {
      CGC_CALL(StrokePath, state_stack_, context_);
    }
    CGC_CALL(RestoreGState, state_stack_, context_);
  }
}

void Renderer::DrawClippedGradient(const std::string &iri) {
  std::string id(iri.begin() + 1, iri.end());
  const Gradient *const *gradient_pp = FindValueOrNull(gradients_, id);
  if (gradient_pp == nullptr || *gradient_pp == nullptr) {
    // TODO: Signal error.
    return;
  }
  const Gradient &gradient = **gradient_pp;
  CGGradientRef cg_gradient = CreateCGGradient(gradient);
  auto delete_cg_gradient = MakeUniquePtr(cg_gradient, CGGradientRelease);

  CGRect bounding_box = CGContextGetPathBoundingBox(context_);
  CGC_CALL(Clip, state_stack_, context_);
  if (gradient.units == Gradient::kUnitsObjectBoundingBox) {
    // kUnitsObjectBoundingBox means the gradient is described in a
    // coordinate system where (0,0) is at the top-left of the object
    // bounding box and (1,1) is at the bottom-right of the object
    // bounding box. See SVG 1.1 Section 13.2.2.
    CGC_CALL(ConcatCTM, state_stack_, context_,
             CGAffineTransformToNormalizeRect(bounding_box));
  }

  // Don't use CGGradientDrawingOptions so that we don't need another
  // template specialization of the value formatter for debug print.
  int gradient_options =
      kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation;

  switch (gradient.type) {
    case Gradient::kTypeLinear: {
      const Gradient::Linear &linear = gradient.linear;
      CGPoint start_point = CGPointMake(EvaluateLength(linear.x1),
                                        EvaluateLength(linear.y1));
      CGPoint end_point = CGPointMake(EvaluateLength(linear.x2),
                                      EvaluateLength(linear.y2));
      for (CGAffineTransform transform : gradient.transforms) {
        CGC_CALL(ConcatCTM, state_stack_, context_, transform);
      }
      CGC_CALL(DrawLinearGradient, state_stack_, context_, cg_gradient,
               start_point, end_point, gradient_options);
      break;
    }
    case Gradient::kTypeRadial: {
      const Gradient::Radial &radial = gradient.radial;
      CGPoint focal_point = CGPointMake(EvaluateLength(radial.fx),
                                        EvaluateLength(radial.fy));
      CGPoint center_point = CGPointMake(EvaluateLength(radial.cx),
                                         EvaluateLength(radial.cy));
      CGFloat radius = EvaluateLength(radial.r);
      for (CGAffineTransform transform : gradient.transforms) {
        CGC_CALL(ConcatCTM, state_stack_, context_, transform);
      }
      CGC_CALL(DrawRadialGradient, state_stack_, context_, cg_gradient,
               focal_point, CGFloat(0.0), center_point, radius,
               gradient_options);
      break;
    }
  }  // switch
}

void Renderer::InitializeCGContext() {
  size_t bitmap_width = static_cast<size_t>(std::floor(canvas_size_.width));
  size_t bitmap_height = static_cast<size_t>(std::floor(canvas_size_.height));
  size_t bitmap_bytes_per_row = bitmap_width * 4;
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  context_ =
      CGBitmapContextCreate(NULL,
                            bitmap_width,
                            bitmap_height,
                            8,
                            bitmap_bytes_per_row,
                            colorSpace,
                            (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
  CGColorSpaceRelease(colorSpace);

  CGC_CALL(ClearRect,
           state_stack_,
           context_,
           CGRectMake(0.f, 0.f, bitmap_width, bitmap_height));

  // These transforms are needed because the coordinate systems of
  // UIImage and CG contexts are flipped from each other.
  // TODO: Figure out how to handle this on OS X.
  CGC_CALL(TranslateCTM,
           state_stack_,
           context_,
           CGFloat(0.f),
           canvas_size_.height);
  CGC_CALL(ScaleCTM,
           state_stack_,
           context_,
           CGFloat(1.f),
           CGFloat(-1.f));
}

Renderer::SVGElementDefinition Renderer::FindElementDefinition(
    const char *name) {
  // TODO: maybe optimize the search.
  for (size_t i = 0; i < svg_element_definitions_.size(); ++i) {
    if (strcmp(name, svg_element_definitions_[i].name) == 0) {
      return svg_element_definitions_[i];
    }
  }
  return kSvgElementUnknown;
}

void Renderer::MergeStyleSheet(const MSCStyleSheet &style_sheet) {
  if (!style_sheet_) {
    style_sheet_.reset(new MSCStyleSheet);
  }
  MSCStyleSheetMerge(style_sheet, style_sheet_.get());
}

}  // namespace internal
}  // namespace metrosvg
