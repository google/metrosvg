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

#import "MetroSVG/iOS/MSVGDocument.h"

#include "MetroSVG/Public/MSCDocument.h"
#import "MetroSVG/iOS/MSVGStyleSheet+Internal.h"

@implementation MSVGDocument {
  MSCDocument *_document;
}

- (instancetype)initWithData:(NSData *)data {
  self = [super init];
  if (self) {
    _document =
        MSCDocumentCreateFromData(reinterpret_cast<const char *>(data.bytes),
                                  data.length,
                                  "");
  }
  return self;
}

- (void)dealloc {
  MSCDocumentDelete(_document);
  _document = NULL;
}

- (CGSize)size {
  return MSCDocumentGetImageSize(_document);
}

- (CGRect)viewBox {
  return MSCDocumentGetImageViewBox(_document);
}

- (UIImage *)imageWithSize:(CGSize)size {
  return [self imageWithSize:size styleSheet:NULL];
}

- (UIImage *)imageWithSize:(CGSize)size
                styleSheet:(MSVGStyleSheet *)styleSheet {
  CGFloat scale = [UIScreen mainScreen].scale;
  CGSize canvasSize = CGSizeMake(size.width * scale, size.height * scale);
  CGImageRef cgImage =
      MSCDocumentCreateCGImage(_document, canvasSize, styleSheet.styleSheet);
  UIImage *uiImage = [UIImage imageWithCGImage:cgImage
                                         scale:[UIScreen mainScreen].scale
                                   orientation:UIImageOrientationUp];
  CGImageRelease(cgImage);
  return uiImage;
}

@end
