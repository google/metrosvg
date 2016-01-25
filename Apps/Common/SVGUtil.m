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

#import "Apps/Common/SVGUtil.h"

#import "MetroSVG/MetroSVG.h"

@implementation SVGUtil

+ (CGImageRef)imageWithSVGFile:(NSString *)file size:(CGSize)size {
  NSData *svgData = [NSData dataWithContentsOfFile:file];
  MSCDocument *document = MSCDocumentCreateFromData([svgData bytes], [svgData length], "");
  CGImageRef image = MSCDocumentCreateCGImage(document, size, NULL);
  MSCDocumentDelete(document);
  return image;
}

+ (void)writeImage:(CGImageRef)image toPNGFile:(NSString *)file {
  NSURL *url = [NSURL fileURLWithPath:file];
  CGImageDestinationRef destination =
      CGImageDestinationCreateWithURL((__bridge CFURLRef)url, kUTTypePNG, 1, NULL);
  CGImageDestinationAddImage(destination, image, NULL);
  CGImageDestinationFinalize(destination);
  CFRelease(destination);
}

@end
