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

/**
 * DTDVerifier verifies an xml file with a given dtd.
 *
 * Usage:
 * $ DTDVerifier xml_file dtd_file
 */

#include <libxml/parser.h>

int main(int argc, const char *argv[]) {
  int status = 0;
  xmlParserCtxtPtr parser_context = 0;
  xmlDocPtr doc = 0;
  xmlDtdPtr dtd = 0;
  xmlValidCtxtPtr valid_context = 0;

  do {
    if (argc < 3) {
      status = 2;
      fprintf(stderr, "Too few arguments.\n");
      break;
    }

    parser_context = xmlNewParserCtxt();
    doc = xmlCtxtReadFile(parser_context, argv[1], NULL, 0);
    if (!doc) {
      status = 3;
      fprintf(stderr, "Can't read xml.\n");
      break;
    }

    dtd = xmlParseDTD(NULL, (const xmlChar *)argv[2]);
    if (!dtd) {
      status = 4;
      fprintf(stderr, "Can't read dtd.\n");
      break;
    }

    valid_context = xmlNewValidCtxt();
    status = xmlValidateDtd(valid_context, doc, dtd) ? 0 : 1;
  } while (0);

  if (parser_context) xmlFreeParserCtxt(parser_context);
  if (doc) xmlFreeDoc(doc);
  if (dtd) xmlFreeDtd(dtd);
  if (valid_context) xmlFreeValidCtxt(valid_context);

  return status;
}
