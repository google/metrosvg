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

#import "StyleCheckerAppDelegate.h"

#import "DirectoryContentsViewController.h"
#import "StyleCheckerViewController.h"

#include "MetroSVG/MetroSVG.h"

@interface StyleCheckerAppDelegate ()<DirectoryContentsViewControllerDataSource>
@end

@implementation StyleCheckerAppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.backgroundColor = [UIColor whiteColor];
  [self.window makeKeyAndVisible];

  NSString *resourcesPath = [[NSBundle mainBundle] resourcePath];
  NSString *testDataPath = [resourcesPath stringByAppendingPathComponent:@"TestData"];
  DirectoryContentsViewController *rootDirectoryViewController =
      [[DirectoryContentsViewController alloc] initWithPaths:@[ testDataPath ] title:@"ROOT"];
  rootDirectoryViewController.dataSource = self;
  UINavigationController *navigationController =
  [[UINavigationController alloc] initWithRootViewController:rootDirectoryViewController];
  self.window.rootViewController = navigationController;

  return YES;
}

#pragma mark DirectoryContentsViewControllerDataSource

- (UIViewController *)
    directoryContentsController:(DirectoryContentsViewController *)directoryContentsController
    viewControllerWithFilePaths:(NSArray *)filePaths {
  return [[StyleCheckerViewController alloc] initWithPath:filePaths[0]
                                                 cssFiles:nil];
}

@end
