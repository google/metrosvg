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

#import "StyleCheckerViewController.h"

#include <cmath>

#include <CoreGraphics/CoreGraphics.h>

#import "MetroSVG/MetroSVG.h"

@class StyleCheckerView;

static const CGFloat kPadding = 16.f;
static const CGFloat kLineWidth = 2.f;
static const CGFloat kCornerRadius = 8.f;

#pragma mark - RoundedRectButton

@interface RoundedRectButton : UIButton

+ (instancetype)button;

@end

@implementation RoundedRectButton

+ (instancetype)button {
  return [self buttonWithType:UIButtonTypeSystem];
}

- (void)drawRect:(CGRect)rect {
  [super drawRect:rect];

  CGRect bounds = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(kLineWidth / 2.f,
                                                                      kLineWidth / 2.f,
                                                                      kLineWidth / 2.f,
                                                                      kLineWidth / 2.f));
  CGFloat left = CGRectGetMinX(bounds);
  CGFloat right = CGRectGetMaxX(bounds);
  CGFloat top = CGRectGetMinY(bounds);
  CGFloat bottom = CGRectGetMaxY(bounds);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);
  CGContextSetLineWidth(context, kLineWidth);
  CGContextBeginPath(context);
  CGContextMoveToPoint(context, left + kCornerRadius, top);
  CGContextAddArcToPoint(context, right, top, right, bottom, kCornerRadius);
  CGContextAddArcToPoint(context, right, bottom, left, bottom, kCornerRadius);
  CGContextAddArcToPoint(context, left, bottom, left, top, kCornerRadius);
  CGContextAddArcToPoint(context, left, top, right, top, kCornerRadius);
  CGContextStrokePath(context);
}

@end

#pragma mark - StyleCheckerViewDelegate

@protocol StyleCheckerViewDelegate <NSObject>

- (void)styleCheckerViewDidTapSelectStyleButton:(StyleCheckerView *)styleCheckerView;
- (void)styleCheckerViewDidTapCustomStyleButton:(StyleCheckerView *)styleCheckerView;
- (void)styleCheckerViewDidTapChangeSizeButton:(StyleCheckerView *)styleCheckerView;
- (void)styleCheckerViewDidTapViewSourceButton:(StyleCheckerView *)styleCheckerView;

@end

#pragma mark - StyleCheckerView

@interface StyleCheckerView : UIView

@property(nonatomic, weak) id<StyleCheckerViewDelegate> delegate;

- (void)setImage:(UIImage *)image;

@end

@implementation StyleCheckerView {
  UIImageView *_imageView;
  RoundedRectButton *_viewSourceButton;
  RoundedRectButton *_changeSizeButton;
  RoundedRectButton *_selectStyleButton;
  RoundedRectButton *_customStyleButton;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor whiteColor];

    _viewSourceButton = [RoundedRectButton button];
    [_viewSourceButton setTitle:@"View source"
                       forState:UIControlStateNormal];
    [_viewSourceButton sizeToFit];
    CGFloat viewSourceButtonHeight = CGRectGetHeight(_viewSourceButton.frame);
    _viewSourceButton.frame =
        CGRectMake(kPadding,
                   CGRectGetMaxY(self.bounds) - kPadding - viewSourceButtonHeight,
                   CGRectGetWidth(self.bounds) - kPadding * 2,
                   viewSourceButtonHeight);
    [_viewSourceButton addTarget:self
                          action:@selector(viewSource)
                forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_viewSourceButton];

    _changeSizeButton = [RoundedRectButton button];
    [_changeSizeButton setTitle:@"Change size"
                       forState:UIControlStateNormal];
    [_changeSizeButton sizeToFit];
    CGFloat changeSizeButtonHeight = CGRectGetHeight(_changeSizeButton.frame);
    _changeSizeButton.frame =
        CGRectMake(kPadding,
                   CGRectGetMinY(_viewSourceButton.frame) - kPadding - changeSizeButtonHeight,
                   CGRectGetWidth(self.bounds) - kPadding * 2,
                   changeSizeButtonHeight);
    [_changeSizeButton addTarget:self
                          action:@selector(changeSize)
                forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_changeSizeButton];

    _selectStyleButton = [RoundedRectButton button];
    [_selectStyleButton setTitle:@"Select style"
                        forState:UIControlStateNormal];
    [_selectStyleButton sizeToFit];
    CGFloat selectStyleButtonWidth = std::floor((CGRectGetWidth(self.bounds) - kPadding * 3) / 2);
    CGFloat selectStyleButtonHeight = CGRectGetHeight(_selectStyleButton.frame);
    _selectStyleButton.frame =
    CGRectMake(kPadding,
               CGRectGetMinY(_changeSizeButton.frame) - kPadding - selectStyleButtonHeight,
               selectStyleButtonWidth,
               selectStyleButtonHeight);
    [_selectStyleButton addTarget:self
                           action:@selector(selectStyle)
                 forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_selectStyleButton];

    _customStyleButton = [RoundedRectButton button];
    [_customStyleButton setTitle:@"Custom style"
                      forState:UIControlStateNormal];
    [_customStyleButton sizeToFit];
    CGFloat customStyleButtonWidth = std::floor((CGRectGetWidth(self.bounds) - kPadding * 3) / 2);
    CGFloat customStyleButtonHeight = CGRectGetHeight(_customStyleButton.frame);
    _customStyleButton.frame =
        CGRectMake(CGRectGetMaxX(self.bounds) - kPadding - customStyleButtonWidth,
                   CGRectGetMinY(_changeSizeButton.frame) - kPadding - customStyleButtonHeight,
                   customStyleButtonWidth,
                   customStyleButtonHeight);
    [_customStyleButton addTarget:self
                         action:@selector(customStyle)
               forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_customStyleButton];

    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(
        std::floor(CGRectGetWidth(frame) / 2.f),
        std::floor(CGRectGetMinY(_customStyleButton.frame) / 2.f),
        0.f,
        0.f)];
    _imageView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
    [self addSubview:_imageView];
  }

  return self;
}

- (void)setImage:(UIImage *)image {
  CGPoint center = _imageView.center;
  _imageView.image = image;
  [_imageView sizeToFit];
  _imageView.center = center;
}

#pragma mark Actions

- (void)viewSource {
  [self.delegate styleCheckerViewDidTapViewSourceButton:self];
}

- (void)changeSize {
  [self.delegate styleCheckerViewDidTapChangeSizeButton:self];
}

- (void)selectStyle {
  [self.delegate styleCheckerViewDidTapSelectStyleButton:self];
}

- (void)customStyle {
  [self.delegate styleCheckerViewDidTapCustomStyleButton:self];
}

@end

#pragma mark - StyleCheckerViewController

@interface StyleCheckerViewController ()<
    StyleCheckerViewDelegate,
    UIActionSheetDelegate,
    UITextViewDelegate>
@end

@implementation StyleCheckerViewController {
  NSString *_path;
  NSData *_data;
  NSArray *_cssFiles;

  NSArray *_styleVariants;
  NSArray *_sizeVariants;

  StyleCheckerView *_styleCheckerView;
  /*
  UIActionSheet *_activeSelectStyleActionSheet;
  UIActionSheet *_activeChangeSizeActionSheet;
   */
  UITextView *_activeTextView;

  CGSize _currentSize;
  NSString *_currentCSSFile;
  NSString *_customCSS;
}

- (instancetype)initWithPath:(NSString *)path
                    cssFiles:(NSArray *)cssFiles {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    BOOL isDirectory = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] &&
        !isDirectory &&
        [[path pathExtension] isEqualToString:@"svg"]) {
      _path = path;
    }
    _cssFiles = cssFiles;
    NSMutableArray *styleVariants = [[NSMutableArray alloc] init];
    for (NSString *css in cssFiles) {
      [styleVariants addObject:@[ css, [css lastPathComponent] ]];
    }
    [styleVariants addObject:@[ @"", @"No style" ]];
    _styleVariants = [styleVariants copy];


    _sizeVariants = @[
        @[ [NSValue valueWithCGSize:CGSizeMake(32, 32)], @"32 x 32" ],
        @[ [NSValue valueWithCGSize:CGSizeMake(64, 64)], @"64 x 64" ],
        @[ [NSValue valueWithCGSize:CGSizeMake(128, 128)], @"128 x 128"],
        @[ [NSValue valueWithCGSize:CGSizeMake(256, 256)], @"256 x 256"],
    ];

    _currentSize = [[_sizeVariants lastObject][0] CGSizeValue];
    _currentCSSFile = nil;
    _customCSS = nil;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  CGRect frame = self.view.bounds;
  CGFloat navBarBottom =
      CGRectGetMaxY(self.navigationController.navigationBar.frame);
  frame = UIEdgeInsetsInsetRect(frame, UIEdgeInsetsMake(navBarBottom, 0.f, 0.f, 0.f));
  _styleCheckerView = [[StyleCheckerView alloc] initWithFrame:frame];
  _styleCheckerView.delegate = self;
  _styleCheckerView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _data = [NSData dataWithContentsOfFile:_path];
  [self redraw];
  [self.view addSubview:_styleCheckerView];
}

#pragma mark StyleCheckerViewDelegate

- (void)styleCheckerViewDidTapSelectStyleButton:(StyleCheckerView *)styleCheckerView {
  /*
  _activeSelectStyleActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                              delegate:self
                                                     cancelButtonTitle:@"Cancel"
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:nil];
  for (NSArray *variant in _styleVariants) {
    [_activeSelectStyleActionSheet addButtonWithTitle:variant[1]];
  }
  [_activeSelectStyleActionSheet showInView:self.view];
   */
}

- (void)styleCheckerViewDidTapCustomStyleButton:(StyleCheckerView *)styleCheckerView {
  UIViewController *viewController = [[UIViewController alloc] init];
  viewController.navigationItem.leftBarButtonItem =
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                    target:self
                                                    action:@selector(cancelEditing)];
  viewController.navigationItem.rightBarButtonItem =
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                    target:self
                                                    action:@selector(doneEditing)];

  UITextView *textView = [[UITextView alloc] initWithFrame:viewController.view.bounds];
  textView.delegate = self;
  textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  textView.editable = YES;
  if (_currentCSSFile) {
    NSError *error;
    textView.text = [NSString stringWithContentsOfFile:_currentCSSFile
                                              encoding:NSUTF8StringEncoding
                                                 error:&error];
  } else if (_customCSS) {
    textView.text = _customCSS;
  }
  [viewController.view addSubview:textView];
  _activeTextView = textView;

  [self.navigationController pushViewController:viewController animated:YES];
}

- (void)styleCheckerViewDidTapChangeSizeButton:(StyleCheckerView *)styleCheckerView {
  /*
  _activeChangeSizeActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
  for (NSArray *variant in _sizeVariants) {
    [_activeChangeSizeActionSheet addButtonWithTitle:variant[1]];
  }
  [_activeChangeSizeActionSheet showInView:self.view];
   */
}

- (void)styleCheckerViewDidTapViewSourceButton:(StyleCheckerView *)styleCheckerView {
  UIViewController *viewController = [[UIViewController alloc] init];

  UITextView *textView = [[UITextView alloc] initWithFrame:viewController.view.bounds];
  textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  textView.editable = NO;
  NSError *error;
  textView.text = [NSString stringWithContentsOfFile:_path
                                            encoding:NSUTF8StringEncoding
                                               error:&error];
  [viewController.view addSubview:textView];

  [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark UIActionSheetDelegate

/*
- (void)actionSheet:(UIActionSheet *)actionSheet
    clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (actionSheet == _activeSelectStyleActionSheet) {
    _activeSelectStyleActionSheet = nil;
    if (buttonIndex == 0) {
      return;
    }
    NSInteger styleIndex = buttonIndex - 1;
    NSString *cssFile = _styleVariants[styleIndex][0];
    if ([cssFile length] == 0) {
      _currentCSSFile = nil;
    } else {
      _currentCSSFile = cssFile;
    }
    _customCSS = nil;
    [self redraw];
  } else if (actionSheet == _activeChangeSizeActionSheet) {
    _activeChangeSizeActionSheet = nil;
    if (buttonIndex == 0) {
      return;
    }
    _currentSize = [_sizeVariants[buttonIndex - 1][0] CGSizeValue];
    [self redraw];
  }
}
 */

#pragma mark Actions

- (void)cancelEditing {
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)doneEditing {
  [self.navigationController popViewControllerAnimated:YES];
  _customCSS = _activeTextView.text;
  _currentCSSFile = nil;
  _activeTextView = nil;
  [self redraw];
}

#pragma mark Private Methods

- (void)redraw {
  NSData *cssData = nil;
  if (_customCSS) {
    cssData = [_customCSS dataUsingEncoding:NSUTF8StringEncoding];
  } else if (_currentCSSFile) {
    cssData = [NSData dataWithContentsOfFile:_currentCSSFile];
  }
  MSVGStyleSheet *styleSheet;
  if (cssData) {
    styleSheet = [[MSVGStyleSheet alloc] initWithData:cssData];
  }

  MSVGDocument *svg = [[MSVGDocument alloc] initWithData:_data];
  CGSize size = _currentSize;
  CGRect viewBox = svg.viewBox;
  if (!CGRectIsNull(viewBox)) {
    CGFloat viewBoxWidth = CGRectGetWidth(viewBox);
    CGFloat viewBoxHeight = CGRectGetHeight(viewBox);
    CGFloat aspectRatio = viewBoxWidth / viewBoxHeight;
    if (aspectRatio > 1) {
      size.height /= aspectRatio;
    } else {
      size.width *= aspectRatio;
    }
  }
  UIImage *image = [svg imageWithSize:size styleSheet:styleSheet];
  [_styleCheckerView setImage:image];
}

@end
