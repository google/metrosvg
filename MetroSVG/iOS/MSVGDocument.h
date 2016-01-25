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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class MSVGStyleSheet;

// MSVGDocument represents an SVG document.
@interface MSVGDocument : NSObject

// The image's intrinsic size as defined by "width" and "height" attributes of
// the outermost svg element. If these attributes are not specified, zero is
// assumed.
@property(nonatomic, readonly) CGSize size;

// Value of "viewBox" attribute of the outermost svg element. Returns CGRectNull
// if the attribute is not specified.
@property(nonatomic, readonly) CGRect viewBox;

// Initializes the receiver with UTF-8-encoded SVG data. The data will be
// partially parsed to populate the receiver's properties.
- (instancetype)initWithData:(NSData *)data;

// Fully parses the data and renders it into a UIImage. The returned image
// has the appropriate density for the screen scale.
- (UIImage *)imageWithSize:(CGSize)size;

// Same as -imageWithSize: but takes an optional style sheet argument.
- (UIImage *)imageWithSize:(CGSize)size styleSheet:(MSVGStyleSheet *)styleSheet;

@end
