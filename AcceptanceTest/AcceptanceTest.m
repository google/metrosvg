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

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#import "Apps/Common/SVGUtil.h"
#include "MetroSVG/MetroSVG.h"

static const CGSize kCanvasSize = {640, 640};

NSString *FullFilePath(NSString *rootDir, NSString *baseName, NSString *extension) {
  NSString *dir = [rootDir stringByAppendingPathComponent:baseName];
  NSString *file = [dir stringByAppendingPathExtension:extension];
  return file;
}

@interface AcceptanceTest : XCTestCase
@end

@implementation AcceptanceTest {
  NSFileManager *_fileManager;
  NSString *_inputSVGDir;
  NSString *_actualPNGDir;
  NSString *_goldenPNGDir;
}

- (void)setUp {
  [super setUp];
  _fileManager = [NSFileManager defaultManager];
  NSString *resourceDir = [NSBundle bundleForClass:[self class]].resourcePath;
  _inputSVGDir = [resourceDir stringByAppendingPathComponent:@"TestData"];
  _actualPNGDir = [resourceDir stringByAppendingPathComponent:@"Actual"];
  _goldenPNGDir = [resourceDir stringByAppendingPathComponent:@"Golden"];

  // Reset the test environment.
  [_fileManager removeItemAtPath:_actualPNGDir error:nil];
  [_fileManager createDirectoryAtPath:_actualPNGDir
          withIntermediateDirectories:YES
                           attributes:nil
                                error:nil];
}

- (void)test {
  NSDirectoryEnumerator *enumerator = [_fileManager enumeratorAtPath:_goldenPNGDir];
  NSString *relPath;
  NSInteger numberOfVerifiedFiles = 0;
  while (relPath = [enumerator nextObject]) {
    NSString *goldenPNGFile = [_goldenPNGDir stringByAppendingPathComponent:relPath];
    BOOL isDirectory;
    [_fileManager fileExistsAtPath:goldenPNGFile isDirectory:&isDirectory];
    if (isDirectory) {
      [_fileManager createDirectoryAtPath:[_actualPNGDir stringByAppendingPathComponent:relPath]
              withIntermediateDirectories:YES
                               attributes:nil
                                    error:nil];
    } else {
      [self verifyDataWithBaseName:[relPath stringByDeletingPathExtension]];
      numberOfVerifiedFiles += 1;
    }
  }
  XCTAssertNotEqual(numberOfVerifiedFiles, 0,
                    @"No file was verified. There should be a bug in the project configurations or "
                    @"the runtime environment.");
}

- (void)verifyDataWithBaseName:(NSString *)baseName {
  // First render the input svg file and save the result as png.
  NSString *inputSVGFile = FullFilePath(_inputSVGDir, baseName, @"svg");
  if (![_fileManager fileExistsAtPath:inputSVGFile]) {
    XCTFail(@"%@: nput SVG file doesn't exist.", baseName);
    return;
  }
  CGImageRef actualImage = [SVGUtil imageWithSVGFile:inputSVGFile size:kCanvasSize];
  NSString *actualPNGFile = FullFilePath(_actualPNGDir, baseName, @"png");
  [SVGUtil writeImage:actualImage toPNGFile:actualPNGFile];
  CGImageRelease(actualImage);

  // Then, compare the actual result with the golden.
  NSData *actualPNGData = [NSData dataWithContentsOfFile:actualPNGFile];
  NSString *goldenPNGFile = FullFilePath(_goldenPNGDir, baseName, @"png");
  NSData *goldenPNGData = [NSData dataWithContentsOfFile:goldenPNGFile];
  XCTAssert([actualPNGData isEqualToData:goldenPNGData],
            @"Detected diff between %@ and %@",
            actualPNGFile,
            goldenPNGFile);
}

@end
