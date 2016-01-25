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

#include <Foundation/Foundation.h>

#include "MetroSVG/MetroSVG.h"

int main(int argc, const char *argv[]) {
  int status = 0;
  MSCDocument *document = 0;
  CGImageRef image = 0;
  CGImageDestinationRef dest = 0;

  do {
    if (argc < 3) {
      status = 4;
      fprintf(stderr, "Too few arguments.\n");
      break;
    }

    NSString *inputFile = [NSString stringWithCString:argv[1]
                                             encoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithContentsOfFile:inputFile];
    if (!data) {
      status = 3;
      fprintf(stderr, "Can't read input.\n");
      break;
    }

    document = MSCDocumentCreateFromData([data bytes], [data length], NULL);
    if (!document) {
      status = 1;
      fprintf(stderr, "Error in parsing SVG.\n");
      break;
    }

    image = MSCDocumentCreateCGImage(document, MSCDocumentGetImageSize(document), NULL);
    if (!image) {
      status = 1;
      fprintf(stderr, "Error in parsing SVG.\n");
      break;
    }

    NSString *outputFile = [NSString stringWithCString:argv[2]
                                              encoding:NSUTF8StringEncoding];
    NSURL *outputURL = [NSURL fileURLWithPath:outputFile];
    dest = CGImageDestinationCreateWithURL((__bridge CFURLRef)outputURL,
                                           kUTTypePNG,
                                           1,
                                           NULL);
    CGImageDestinationAddImage(dest, image, NULL);
    if (!CGImageDestinationFinalize(dest)) {
      status = 2;
      fprintf(stderr, "Can't write output.\n");
      break;
    }
  } while (0);

  if (document) MSCDocumentDelete(document);
  if (image) CGImageRelease(image);
  if (dest) CFRelease(dest);

  return status;
}
