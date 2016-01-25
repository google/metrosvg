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

#import "Apps/Common/SVGUtil.h"

static const CGSize kCanvasSize = {640, 640};

// Renders all files under |inputDir| with an extension of .svg
// into the same relative path under |outputDir| as .png files.
static void RenderSVGFiles(NSString *inputDir, NSString *outputDir) {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:inputDir];
  NSString *relPath;

  while (relPath = [enumerator nextObject]) {
    NSString *inputPath = [inputDir stringByAppendingPathComponent:relPath];
    BOOL isDirectory;
    [fileManager fileExistsAtPath:inputPath isDirectory:&isDirectory];
    if (isDirectory) {
      NSError *error;
      NSString *outputPath = [outputDir stringByAppendingPathComponent:relPath];
      [fileManager createDirectoryAtPath:outputPath
             withIntermediateDirectories:YES
                              attributes:nil
                                   error:&error];
    } else if ([[relPath pathExtension] isEqualToString:@"svg"]) {
      NSString *relPathNoExtension = [relPath stringByDeletingPathExtension];
      NSString *relPathPNG = [relPathNoExtension stringByAppendingPathExtension:@"png"];
      NSString *outputPath = [outputDir stringByAppendingPathComponent:relPathPNG];
      CGImageRef image = [SVGUtil imageWithSVGFile:inputPath
                                              size:kCanvasSize];
      [SVGUtil writeImage:image toPNGFile:outputPath];
      CGImageRelease(image);
    }
  }
}

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    NSString *inputDir = @"/tmp/SVG/TestData";
    NSString *outputDir = @"/tmp/SVG/Output";
    RenderSVGFiles(inputDir, outputDir);
  }
  return 0;
}
