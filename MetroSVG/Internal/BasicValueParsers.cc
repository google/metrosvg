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

#include "MetroSVG/Internal/BasicValueParsers.h"

#include <algorithm>
#include <cctype>
#include <cmath>

#include "MetroSVG/Internal/Macros.h"

namespace metrosvg {
namespace internal {

namespace {

template<typename Word>
struct DictionaryEntry {
  const char *word_string;
  Word word;
};

// Consumes entry->word_string where entry is one of the entries in "dictionary"
// and set corresponding entry->word to "word".
template<typename Word>
bool ConsumeVocabulary(
    StringPiece *s,
    const DictionaryEntry<Word> *dictionary,
    size_t dictionary_size,
    Word *word) {
  for (size_t i = 0; i < dictionary_size; ++i) {
    const DictionaryEntry<Word> &entry = dictionary[i];
    size_t word_len = strlen(entry.word_string);
    if (strncmp(entry.word_string, s->begin(), word_len) == 0) {
      *word = entry.word,
      s->Advance(word_len);
      return true;
    }
  }
  return false;
}

template<typename Arg0>
bool GenericParse1(bool (*consume)(StringPiece *, Arg0),
                   StringPiece s,
                   Arg0 arg0) {
  return consume(&s, arg0) && s.length() == 0;
}

template<typename Arg0, typename Arg1>
bool GenericParse2(bool (*consume)(StringPiece *, Arg0, Arg1),
                   StringPiece s,
                   Arg0 arg0,
                   Arg1 arg1) {
  return consume(&s, arg0, arg1) && s.length() == 0;
}

template<typename Value>
bool GenericConsumeValues(bool (*consume_value)(StringPiece *, Value *),
                          bool (*consume_delimiter)(StringPiece *),
                          StringPiece *s,
                          int count,
                          Value *varray,
                          bool is_delemeter_optional) {
  StringPiece s_copy = *s;
  for (int i = 0; i < count; ++i) {
    if (i != 0) {
      if (!consume_delimiter(&s_copy) && !is_delemeter_optional) {
        return false;
      }
    }
    if (!consume_value(&s_copy, varray + i)) {
      return false;
    }
  }
  s->Advance(s_copy.begin() - s->begin());
  return true;
}

}  // namespace

bool ConsumeNumberDelimiter(StringPiece *s) {
  // A single comma surrounded by any amount of whitespace
  // constitutes a valid delimiter.
  const char *it = s->begin();
  bool seen_comma = false;
  while (it != s->end()) {
    if ((*it) == ',') {
      if (seen_comma) {
        break;
      }
      seen_comma = true;
    } else if (!isspace(*it)) {
      break;
    }
    ++it;
  }
  if (seen_comma) {
    s->Advance(it - s->begin());
    return true;
  } else {
    return false;
  }
}

bool ConsumeDecimalInt(StringPiece *s, int *n) {
  int ret = 0;
  const char *iter = s->begin();
  for (; iter != s->end(); ++iter) {
    char c = *iter;
    if ('0' <= c && c <= '9') {
      ret *= 10;
      ret += c - '0';
    } else {
      break;
    }
  }
  if (iter != s->begin()) {
    *n = ret;
    s->Advance(iter - s->begin());
    return true;
  } else {
    return false;
  }
}

bool ConsumeDecimalIntPercent(StringPiece *s, int *n) {
  StringPiece s_copy = *s;
  if (ConsumeDecimalInt(&s_copy, n) &&
      s_copy.length() != 0 &&
      s_copy[0] == '%') {
    s->Advance((s->length() - s_copy.length()) + 1);
    return true;
  } else {
    return false;
  }
}

bool ConsumeHexInt(StringPiece *s, int requested_width, int *n) {
  int result = 0;
  const char *iter = s->begin();
  const char *limit = s->end();
  if (requested_width > 0) {
    if (static_cast<intptr_t>(s->length()) < requested_width) {
      return false;
    }
    if (requested_width < static_cast<intptr_t>(s->length())) {
      limit = iter + requested_width;
    }
  }
  for (; iter < limit; ++iter) {
    char c = *iter;
    if (ishexnumber(c)) {
      result = result * 16 + digittoint(c);
    } else {
      break;
    }
  }
  intptr_t parsed_length = iter - s->begin();
  if ((requested_width > 0) && (parsed_length < requested_width)) {
    return false;
  }
  if (iter != s->begin()) {
    *n = result;
    s->Advance(parsed_length);
    return true;
  } else {
    return false;
  }
}

bool ConsumeSign(StringPiece *s) {
  if (s->length()) {
    char c = *s->begin();
    if (c == '-') {
      s->Advance(1);
      return true;
    }
  }
  return false;
}

bool ConsumeFloat(StringPiece *s, CGFloat *f) {
  bool base_is_negative = false;
  int base_integer = 0;
  int fraction_as_int = 0;

  StringPiece after_sign(*s);
  ConsumeWhitespace(&after_sign);
  base_is_negative = ConsumeSign(&after_sign);

  StringPiece after_base(after_sign);
  ConsumeDecimalInt(&after_base, &base_integer);
  bool had_base_integer = after_base.begin() != after_sign.begin();

  size_t base_fraction_length = 0;
  if (after_base.length()) {
    const char maybe_decimal_point = *after_base.begin();
    if (maybe_decimal_point == '.') {
      after_base.Advance(1);
      const char *before_fraction = after_base.begin();
      if (ConsumeDecimalInt(&after_base, &fraction_as_int)) {
        base_fraction_length = after_base.begin() - before_fraction;
      }
    }
  }
  // Must have non-empty base or fraction.
  if (!had_base_integer && !base_fraction_length) {
    return false;
  }
  CGFloat fraction_value =
      fraction_as_int / std::powf(10, base_fraction_length);
  CGFloat value = (base_is_negative ? -1 : 1) * (base_integer + fraction_value);

  if (after_base.length()) {
    StringPiece reading_exponent(after_base);
    const char maybe_e = *reading_exponent.begin();
    if (maybe_e == 'e') {
      reading_exponent.Advance(1);
      int exponent = 0;
      bool exponent_is_negative = false;
      exponent_is_negative = ConsumeSign(&reading_exponent);
      if (ConsumeDecimalInt(&reading_exponent, &exponent)) {
        value *= std::pow(10, (exponent_is_negative ? -1 : 1) * exponent);
        after_base.Advance(reading_exponent.begin() - after_base.begin());
      }
    }
  }
  if (isinf(value)) {
    return false;
  }
  *f = value;
  s->Advance(after_base.begin() - s->begin());
  return true;
}

bool ParseFloat(StringPiece s, CGFloat *f) {
  return GenericParse1(ConsumeFloat, s, f);
}

bool ConsumeFloats(StringPiece *s, int count, CGFloat *farray) {
  return GenericConsumeValues(ConsumeFloat, ConsumeNumberDelimiter,
                              s, count, farray, true);
}

bool ParseFloats(StringPiece s, int count, CGFloat *farray) {
  return GenericParse2(ConsumeFloats, s, count, farray);
}

static const DictionaryEntry<Length::Unit> kLengthUnitDictionary[] = {
  {"cm", Length::kUnitCm},
  {"em", Length::kUnitEm},
  {"ex", Length::kUnitEx},
  {"in", Length::kUnitIn},
  {"mm", Length::kUnitMm},
  {"pc", Length::kUnitPc},
  {"%", Length::kUnitPercent},
  {"pt", Length::kUnitPt},
  {"px", Length::kUnitPx},
};

bool ConsumeLength(StringPiece *s, Length *length) {
  StringPiece s_copy = *s;
  CGFloat f;
  if (!ConsumeFloat(&s_copy, &f)) {
    return false;
  }
  Length::Unit unit;
  if (!ConsumeVocabulary(&s_copy,
                         kLengthUnitDictionary,
                         ARRAYSIZE(kLengthUnitDictionary),
                         &unit)) {
    unit = Length::kUnitNone;
  }
  s->Advance(s->length() - s_copy.length());
  length->value = f;
  length->unit = unit;
  return true;
}

bool ParseLength(StringPiece s, Length *length) {
  return GenericParse1(ConsumeLength, s, length);
}

bool ConsumeLengths(StringPiece *s, std::vector<Length> *lengths) {
  bool consumed = false;
  while (s->length() > 0) {
    Length length;
    if (!ConsumeLength(s, &length)) {
      break;
    }
    consumed = true;
    lengths->push_back(length);
    ConsumeNumberDelimiter(s);
  }
  return consumed;
}

bool ParseLengths(StringPiece s, std::vector<Length> *lengths) {
  return GenericParse1(ConsumeLengths, s, lengths);
}

bool ConsumeParenthesizedFloats(StringPiece *s,
                                int count,
                                CGFloat *out_floats) {
  StringPiece s_copy = *s;
  if (!ConsumeString(&s_copy, "(", true)) {
    return false;
  }
  ConsumeWhitespace(&s_copy);
  if (!ConsumeFloats(&s_copy, count, out_floats)) {
    return false;
  }
  ConsumeWhitespace(&s_copy);
  if (!ConsumeString(&s_copy, ")", true)) {
    return false;
  }
  s->Advance(s_copy.begin() - s->begin());
  return true;
}

bool PeekAlpha(StringPiece s, char *c) {
  char first_char = s[0];
  if (('a' <= first_char && first_char <= 'z') ||
      ('A' <= first_char && first_char <= 'Z')) {
    *c = first_char;
    return true;
  } else {
    return false;
  }
}

bool ConsumeAlpha(StringPiece *s, char *c) {
  bool found = PeekAlpha(*s, c);
  if (found) {
    s->Advance(1);
  }
  return found;
}

bool ConsumeString(StringPiece *s, const char *string, bool case_sensitive) {
  size_t string_len = strlen(string);
  if (s->length() < string_len) {
    return false;
  }

  int (*cmp_func)(const char *, const char *, size_t) =
      case_sensitive ? strncmp : strncasecmp;
  if (cmp_func(s->begin(), string, string_len) == 0) {
    s->Advance(string_len);
    return true;
  } else {
    return false;
  }
}

bool ConsumeFlag(StringPiece *s, bool *flag) {
  StringPiece s_copy = *s;
  ConsumeWhitespace(&s_copy);
  if (s_copy.length() == 0) {
    return false;
  }
  char c = s_copy[0];
  // The specification instructs implementations to take any nonzero value
  // to mean the value 1.
  // http://www.w3.org/TR/SVG11/implnote.html#ArcImplementationNotes
  // However, the test suite that W3C provides and other major implementations
  // treat values other than 0 and 1 as an error. We follow this convention.
  if (c != '0' && c != '1') {
    return false;
  }
  *flag = (c != '0');
  s->Advance(s->length() - s_copy.length() + 1);
  return true;
}

#if SVG_COLOR_KEYWORD_SUPPORT

// Returns the standard SVG color for the given string,
// if it exists; otherwise NULL.
bool ConsumeStandardSVGColor(
    StringPiece *sp,
    const SvgStandardColorDefinition **out_standardColor) {
  StringPiece s_copy = *sp;
  ConsumeWhitespace(&s_copy);
  // Find the initial alphabetic substring.
  size_t token_length = 0;
  for (const char *c = s_copy.begin(); c < s_copy.end() && isalpha(*c); c++) {
    token_length++;
  }
  const StringPiece token(s_copy.begin(), token_length);
  const SvgStandardColorDefinition *standardColor =
      FindSVGStandardColorOrNull(token);
  if (!standardColor) {
    return false;
  }
  sp->Advance(token.begin() - sp->begin() + token.length());
  *out_standardColor = standardColor;
  return true;
}

#endif  // SVG_COLOR_KEYWORD_SUPPORT

bool ConsumeHexadecimalColor(StringPiece *s, RgbColor *rgb) {
  if ((*s)[0] != '#') {
    return false;
  }
  StringPiece s_copy(s->begin() + 1, s->length() - 1);
  // Call ConsumeHexInt with unlimited width to find out how many hex digits
  // there are; make sure there are at least 3 hex digits.
  StringPiece after_hex_digits(s_copy);
  int color_int;
  if (!ConsumeHexInt(&after_hex_digits, -1, &color_int)) {
    return false;
  }
  size_t hex_digit_count = after_hex_digits.begin() - s_copy.begin();
  if (hex_digit_count < 3) {
    return false;
  }
  // Now we know we have enough hex digits to consume either a three-digit
  // or six-digit hex color.
  CGFloat color_comps[3];
  bool is_three_digits = (hex_digit_count < 6);
  for (int i = 0; i < 3 ; i++) {
    if (!ConsumeHexInt(&s_copy, is_three_digits ? 1 : 2, &color_int)) {
      return false;
    }
    color_comps[i] = color_int / (is_three_digits ? 15.f : 255.f);
  }
  *rgb = RgbColor(color_comps[0], color_comps[1], color_comps[2]);
  s->Advance(s_copy.begin() - s->begin());
  return true;
}

bool ConsumeFunctionalColor(StringPiece *s, RgbColor *rgb) {
  StringPiece s_copy = *s;
  if (!ConsumeString(&s_copy, "rgb(", false)) {
    return false;
  }
  ConsumeWhitespace(&s_copy);

  int components[3];
  if (GenericConsumeValues(ConsumeDecimalInt, ConsumeNumberDelimiter,
                           &s_copy, 3, components, false)) {
    *rgb = RgbColor(components[0] / 255.f,
                    components[1] / 255.f,
                    components[2] / 255.f);
  } else if (GenericConsumeValues(ConsumeDecimalIntPercent,
                                  ConsumeNumberDelimiter,
                                  &s_copy, 3, components, false)) {
    *rgb = RgbColor(components[0] / 100.f,
                    components[1] / 100.f,
                    components[2] / 100.f);
  } else {
    return false;
  }

  ConsumeWhitespace(&s_copy);
  if (!ConsumeString(&s_copy, ")", true)) {
    return false;
  }

  s->Advance(s->length() - s_copy.length());
  return true;
}

bool ConsumeRgbColor(StringPiece *s, RgbColor *rgb) {
#if SVG_COLOR_KEYWORD_SUPPORT
  const SvgStandardColorDefinition *standardColor;
  if (ConsumeStandardSVGColor(s, &standardColor)) {
    *rgb = RgbColor(standardColor->red / 255.f,
                    standardColor->green / 255.f,
                    standardColor->blue / 255.f);
    return true;
  }
#endif  // SVG_COLOR_KEYWORD_SUPPORT

  if (ConsumeHexadecimalColor(s, rgb)) {
    return true;
  }
  if (ConsumeFunctionalColor(s, rgb)) {
    return true;
  }
  return false;
}

bool ParseRgbColor(StringPiece s, RgbColor *rgb) {
  return GenericParse1(ConsumeRgbColor, s, rgb);
}

bool ConsumeWhitespace(StringPiece *s) {
  const char *it = s->begin();
  while (it != s->end() && (isspace(*it))) {
    ++it;
  }
  if (it != s->begin()) {
    s->Advance(it - s->begin());
    return true;
  } else {
    return false;
  }
}

StringPiece TrimTrailingWhitespace(const StringPiece &s) {
  size_t non_whitespace_length = s.length();
  while (non_whitespace_length > 0) {
    const char last_char = *(s.begin() + non_whitespace_length - 1);
    if (!isspace(last_char)) {
      return StringPiece(s.begin(), non_whitespace_length);
    }
    non_whitespace_length--;
  }
  return StringPiece();
}

bool ConsumeIri(StringPiece *s, StringPiece *iri) {
  StringPiece s_copy(*s);
  ConsumeWhitespace(&s_copy);
  if (!ConsumeString(&s_copy, "url(", true)) {
    return false;
  }
  size_t pos = s_copy.find(")");
  if (pos == std::string::npos) {
    return false;
  }
  *iri = StringPiece(s_copy.begin(), pos);
  s->Advance(s_copy.begin() - s->begin() + pos + 1);
  return true;
}

bool ParseIri(StringPiece s, StringPiece *iri) {
  return GenericParse1(ConsumeIri, s, iri);
}

namespace {
enum InternalAlignment {
  kInternalAlignmentNone,
  kInternalAlignmentXMinYMin,
  kInternalAlignmentXMidYMin,
  kInternalAlignmentXMaxYMin,
  kInternalAlignmentXMinYMid,
  kInternalAlignmentXMidYMid,
  kInternalAlignmentXMaxYMid,
  kInternalAlignmentXMinYMax,
  kInternalAlignmentXMidYMax,
  kInternalAlignmentXMaxYMax,
};

static const DictionaryEntry<InternalAlignment>
kInternalAlignmentDictionary[] = {
  {"none", kInternalAlignmentNone},
  {"xMinYMin", kInternalAlignmentXMinYMin},
  {"xMidYMin", kInternalAlignmentXMidYMin},
  {"xMaxYMin", kInternalAlignmentXMaxYMin},
  {"xMinYMid", kInternalAlignmentXMinYMid},
  {"xMidYMid", kInternalAlignmentXMidYMid},
  {"xMaxYMid", kInternalAlignmentXMaxYMid},
  {"xMinYMax", kInternalAlignmentXMinYMax},
  {"xMidYMax", kInternalAlignmentXMidYMax},
  {"xMaxYMax", kInternalAlignmentXMaxYMax},
};

static const DictionaryEntry<PreserveAspectRatio::MeetOrSlice>
kMeetOrSliceDictionary[] = {
  {"meet", PreserveAspectRatio::kMeet},
  {"slice", PreserveAspectRatio::kSlice},
};
}  // namespace

bool ConsumePreserveAspectRatio(StringPiece *s,
                                PreserveAspectRatio *aspect_ratio) {
  StringPiece s_copy(*s);

  ConsumeWhitespace(&s_copy);
  bool defer = false;
  if (ConsumeString(&s_copy, "defer", true)) {
    defer = true;
  }

  ConsumeWhitespace(&s_copy);
  InternalAlignment alignment = kInternalAlignmentXMidYMid;
  if (!ConsumeVocabulary(&s_copy,
                         kInternalAlignmentDictionary,
                         ARRAYSIZE(kInternalAlignmentDictionary),
                         &alignment)) {
    return false;
  }
  bool no_alignment = (alignment == kInternalAlignmentNone);
  PreserveAspectRatio::Alignment x_alignment;
  PreserveAspectRatio::Alignment y_alignment;
  switch (alignment) {
    case kInternalAlignmentXMinYMin:
    case kInternalAlignmentXMinYMid:
    case kInternalAlignmentXMinYMax:
      x_alignment = PreserveAspectRatio::kMin;
      break;
    case kInternalAlignmentXMidYMin:
    case kInternalAlignmentXMidYMid:
    case kInternalAlignmentXMidYMax:
    case kInternalAlignmentNone:
      x_alignment = PreserveAspectRatio::kMid;
      break;
    case kInternalAlignmentXMaxYMin:
    case kInternalAlignmentXMaxYMid:
    case kInternalAlignmentXMaxYMax:
      x_alignment = PreserveAspectRatio::kMax;
      break;
  }
  switch (alignment) {
    case kInternalAlignmentXMinYMin:
    case kInternalAlignmentXMidYMin:
    case kInternalAlignmentXMaxYMin:
      y_alignment = PreserveAspectRatio::kMin;
      break;
    case kInternalAlignmentXMinYMid:
    case kInternalAlignmentXMidYMid:
    case kInternalAlignmentXMaxYMid:
    case kInternalAlignmentNone:
      y_alignment = PreserveAspectRatio::kMid;
      break;
      case kInternalAlignmentXMinYMax:
    case kInternalAlignmentXMidYMax:
    case kInternalAlignmentXMaxYMax:
      y_alignment = PreserveAspectRatio::kMax;
      break;
  }

  ConsumeWhitespace(&s_copy);
  PreserveAspectRatio::MeetOrSlice meet_or_slice = PreserveAspectRatio::kMeet;
  ConsumeVocabulary(&s_copy,
                    kMeetOrSliceDictionary,
                    ARRAYSIZE(kMeetOrSliceDictionary),
                    &meet_or_slice);

  aspect_ratio->defer = defer;
  aspect_ratio->no_alignment = no_alignment;
  aspect_ratio->x_alignment = x_alignment;
  aspect_ratio->y_alignment = y_alignment;
  aspect_ratio->meet_or_slice = meet_or_slice;
  s->Advance(s_copy.begin() - s->begin());
  return true;
}

bool ParsePreserveAspectRatio(StringPiece s,
                              PreserveAspectRatio *aspect_ratio) {
  return GenericParse1(ConsumePreserveAspectRatio, s, aspect_ratio);
}

}  // namespace internal
}  // namespace metrosvg
