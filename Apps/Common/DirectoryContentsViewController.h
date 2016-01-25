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

#import <UIKit/UIKit.h>

@protocol DirectoryContentsViewControllerDataSource;

/**
 * DirectoryContentsViewController implements traversal of directory trees using
 * usual combination of table views and the navigation stack. When traversal
 * reaches a tree leave (non-directory files), it creates a view controller from
 * its data source that presents files in a way specific to the application.
 *
 * It can handle multiple parallel directory trees.
 */
@interface DirectoryContentsViewController : UITableViewController

@property(nonatomic, weak) id<DirectoryContentsViewControllerDataSource> dataSource;

- (instancetype)initWithPaths:(NSArray *)paths title:(NSString *)title;

@end

@protocol DirectoryContentsViewControllerDataSource <NSObject>

- (UIViewController *)
    directoryContentsController:(DirectoryContentsViewController *)directoryContentsController
    viewControllerWithFilePaths:(NSArray *)filePaths;

@end
