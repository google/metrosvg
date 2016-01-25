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

#include <map>
#include <string>
#include <unordered_set>
#include <vector>

#include <libxml/xmlreader.h>

#include "MetroSVG/Internal/BasicTypes.h"
#include "MetroSVG/MetroSVG.h"

struct CGContext;

namespace metrosvg {
namespace internal {

struct Gradient;
class PathDataIterator;
class StringPiece;

class Renderer {
 public:
  Renderer();
  ~Renderer();
  CGImageRef CreateCGImageFromMSCDocument(MSCDocument *document,
                                          CGSize canvas_size,
                                          const MSCStyleSheet *style_sheet);

 private:
  typedef void (Renderer::*BeginElementHandler)(const StringMap &attributes,
                                                const StringMap &styles);
  typedef void (Renderer::*EndElementHandler)();

  // As part of the explicit GraphicsState below, we keep whether to
  // paint or not, and whether to paint with a gradient, for each
  // possible paint operation (fill and stroke).
  struct PaintState {
    bool should_paint;
    RgbColor color;
    std::string iri;
    CGFloat opacity;

    explicit PaintState(bool paint_default, const RgbColor color_default)
        : should_paint(paint_default),
          color(color_default),
          iri(),
          opacity(1.0) {}

    void set_should_paint(bool new_should_paint) {
      should_paint = new_should_paint;
      if (!new_should_paint) {
        iri.clear();
      }
    }

    void set_color(RgbColor new_color) {
      should_paint = true;
      color = new_color;
      iri.clear();
    }

    void set_iri(const std::string &new_iri) {
      should_paint = true;
      iri = new_iri;
    }

    void ApplyOpacity(CGFloat additional_opacity) {
      opacity *= additional_opacity;
    }
  };

  // Most paint state is maintained directly on the CoreGraphics
  // GState stack.  However, we need to specifically know the value
  // of some items that cannot be read back out of the CGState,
  // so we maintain a local version of a few graphics state items.
  struct GraphicsState {
    PaintState fill;
    FillRule fill_rule;
    PaintState stroke;
    LineDash line_dash;
    // This tracks the value of the "display" attribute.
    bool display;
    // This tracks the value of the "visibility" attribute,
    // which inherits differently than "display".  See
    // SVG 1.1 Section 11.5.
    bool visibility;

    // States related to gradients.
    RgbColor stop_color;
    CGFloat stop_opacity;

    // The default value of fill is black, but for stroke it's none.
    GraphicsState()
        : fill(true, RgbColor(0.0f, 0.0f, 0.0f)),
          fill_rule(kFillRuleNonZero),
          stroke(false, RgbColor(0.0f, 0.0f, 0.0f)),
          display(true),
          visibility(true),
          stop_color(0, 0, 0),
          stop_opacity(1) {}
  };

  struct SVGElementDefinition {
    const char *name;
    BeginElementHandler begin_handler;
    EndElementHandler end_handler;
  };

  struct State {
    SVGElementDefinition element_definition;
    int element_line_number;
    int element_column_number;
    GraphicsState graphics;
    bool defines_transparency_layer;
    std::string style_text_;
    std::string style_type_;

    State(SVGElementDefinition element,
          int line_number,
          int column_number,
          GraphicsState this_graphics)
        : element_definition(element),
          element_line_number(line_number),
          element_column_number(column_number),
          graphics(this_graphics),
          defines_transparency_layer(false) {}
  };

  // Internal constants.
  static const SVGElementDefinition kSvgElementRoot;
  static const SVGElementDefinition kSvgElementUnknown;

  // Internal variables.
  const std::unordered_set<std::string> supported_styles_;
  CGContext *context_;
  CGSize canvas_size_;
  CGFloat x_scale_;
  CGFloat y_scale_;
  xmlTextReader *reader_;
  std::vector<State> state_stack_;
  std::unique_ptr<Gradient> pending_gradient_;
  std::map<std::string, Gradient *> gradients_;
  GraphicsState graphics_;
  std::unique_ptr<MSCStyleSheet> style_sheet_;

  // TODO: Make this a constant.
  std::vector<SVGElementDefinition> svg_element_definitions_;

  void BeginElement(const char *name,
                    const StringMap &attributes,
                    const StringMap &styles);
  void EndElement(const char *name);

  void ProcessCircleElement(const StringMap &attributes,
                            const StringMap &styles);
  void ProcessEllipseElement(const StringMap &attributes,
                             const StringMap &styles);
  void ProcessGElement(const StringMap &attributes,
                       const StringMap &styles);
  void ProcessLineElement(const StringMap &attributes,
                          const StringMap &styles);

  void BeginLinearGradientElement(const StringMap &attributes,
                                  const StringMap &styles);
  void EndLinearGradientElement();

  void ProcessPathElement(const StringMap &attributes,
                          const StringMap &styles);
  void ProcessPolygonElement(const StringMap &attributes,
                             const StringMap &styles);
  void ProcessPolylineElement(const StringMap &attributes,
                              const StringMap &styles);

  void BeginRadialGradientElement(const StringMap &attributes,
                                  const StringMap &styles);
  void EndRadialGradientElement();

  void ProcessRectElement(const StringMap &attributes,
                          const StringMap &styles);
  void ProcessStopElement(const StringMap &attributes,
                          const StringMap &styles);

  void BeginStyleElement(const StringMap &attributes,
                         const StringMap &styles);
  void EndStyleElement();

  void ProcessSvgElement(const StringMap &attributes,
                         const StringMap &styles);

  // Attempts to process the given name and value that can be specified
  // as an attribute and a style.
  //
  // It returns whether the given name/value pair was a
  // known style (in which case it will have been processed).
  bool ProcessStyle(const std::string &name,
                    const std::string &value);
  // This is a helper function to process the value of a fill
  // or stroke attribute.
  void ProcessFillOrStrokeValue(const std::string &value, bool is_fill);

  // Set the current fill or stroke color in the current context
  // based on the graphics state.
  void CallCGSetColor(bool is_fill);

  void ProcessDisplayValue(const std::string &value);
  void ProcessVisibilityValue(const std::string &value);
  void ProcessOpacityValue(const std::string &value);
  void ProcessFillRuleValue(const std::string &value);
  void ProcessDashArrayValue(const std::string &value);
  void ProcessDashOffsetValue(const std::string &value);

  // Returns true if all attributes and styles are processed successfully.
  // Returns false if there was an any error.
  bool ProcessCommonAttributes(StringMap *unprocessed_attributes,
                               StringMap *unprocessed_styles);

  // Iterates through all the elements returned by the given
  // iterator and defines the result as the path in the current
  // graphics context.
  void ProcessPathData(PathDataIterator *iter);

  // Takes an path data iterator that points to an arc
  // and add the arc to a path.
  // If an error(Out-of-range etc) occured,
  // returns false without mutating the path.
  bool AddEllipticalArcToPath(const PathDataIterator &iter,
                              CGMutablePathRef *path);

  // Called to handle a paintable element with a points= attribute
  // (either polygon or polyline).
  void PaintPolyElement(const StringMap &attributes, bool implicit_close);

  // This routine should be called to handle the painting of
  // any element based on previously set fill/stroke options.
  // The callback takes a context and should
  // set the path to be painted into the context.
  // The |is_fillable| parameter may be false to indicate that the
  // type of element being painted is not logically fillable
  // (line and polyline).
  void PaintElement(std::function<void(CGContextRef context)> define_path,
                    bool is_fillable);

  // This routine is a helper which will draw the gradient referenced
  // by the given iri clipped by the current path.
  void DrawClippedGradient(const std::string &iri);

  // Helper functions.
  void InitializeCGContext();
  SVGElementDefinition FindElementDefinition(const char *name);

  // Merge css into class variable style_sheet_, create an instance
  // if style_sheet_ is a nullptr.
  void MergeStyleSheet(const MSCStyleSheet &style_sheet);
};

}  // namespace internal
}  // namespace metrosvg
