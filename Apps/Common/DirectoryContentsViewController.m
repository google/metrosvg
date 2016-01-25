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

#import "DirectoryContentsViewController.h"

#pragma mark - DirectoryContent

@interface DirectoryContent : NSObject

@property(nonatomic, strong, readonly) NSString *name;
@property(nonatomic, assign, readonly) BOOL isDirectory;

- (instancetype)initWithName:(NSString *)name isDirectory:(BOOL)isDirectory;

+ (NSArray *)directoryContentsInDirectoryAtPath:(NSString *)path;

@end

@implementation DirectoryContent

- (instancetype)initWithName:(NSString *)name isDirectory:(BOOL)isDirectory {
  self = [super init];
  if (self) {
    _name = name;
    _isDirectory = isDirectory;
  }
  return self;
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[self class]]) {
    return NO;
  }
  DirectoryContent *otherContent = (DirectoryContent *)other;
  return [_name isEqualToString:otherContent.name] && _isDirectory == otherContent.isDirectory;
}

- (NSUInteger)hash {
  NSUInteger hash = [_name hash];
  hash = hash * 13 + (_isDirectory ? 7 : 0);
  return hash;
}

+ (NSArray *)directoryContentsInDirectoryAtPath:(NSString *)path {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSArray *rawContents = [fileManager contentsOfDirectoryAtPath:path error:nil];
  NSMutableArray *contents = [NSMutableArray array];
  for (NSString *rawContent in rawContents) {
    if ([rawContent isEqualToString:@".DS_Store"]) {
      continue;
    }
    NSString *contentPath = [path stringByAppendingPathComponent:rawContent];
    BOOL isDirectory;
    if ([fileManager fileExistsAtPath:contentPath isDirectory:&isDirectory]) {
      DirectoryContent *content =
          [[DirectoryContent alloc] initWithName:rawContent isDirectory:isDirectory];
      [contents addObject:content];
    }
  }
  return [contents copy];
}

@end

#pragma mark - DirectoryContentsViewController

@implementation DirectoryContentsViewController {
  NSArray *_paths;  // of NSString.
  NSArray *_commonContents;  // of NSString.
}

- (instancetype)initWithPaths:(NSArray *)paths title:(NSString *)title {
  self = [super initWithStyle:UITableViewStylePlain];
  if (self) {
    self.title = title;

    _paths = [paths copy];

    NSMutableSet *commonContents;
    for (NSString *path in paths) {
      NSArray *contents = [DirectoryContent directoryContentsInDirectoryAtPath:path];
      if (commonContents) {
        [commonContents intersectSet:[NSSet setWithArray:contents]];
      } else {
        commonContents = [NSMutableSet setWithArray:contents];
      }
    }
    _commonContents =
        [[commonContents allObjects] sortedArrayUsingComparator:^(DirectoryContent *c1,
                                                                  DirectoryContent *c2) {
          return [c1.name compare:c2.name];
        }];
  }
  return self;
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [_commonContents count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *const kReuseIdentifier = @"DirectoryContentsViewController";
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:kReuseIdentifier];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:kReuseIdentifier];
  }
  DirectoryContent *content = _commonContents[indexPath.row];
  NSString *icon = content.isDirectory ? @"\U0001F4C1"  // directory icon.
                                       : @"\U0001F4C4";  // file icon.
  cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", icon, content.name];
  return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  DirectoryContent *content = _commonContents[indexPath.row];

  NSMutableArray *newPaths = [NSMutableArray array];
  for (NSString *p in _paths) {
    NSString *newPath = [p stringByAppendingPathComponent:content.name];
    [newPaths addObject:newPath];
  }
  if (content.isDirectory) {
    DirectoryContentsViewController *newController =
        [[DirectoryContentsViewController alloc] initWithPaths:newPaths title:content.name];
    newController.dataSource = _dataSource;
    [self.navigationController pushViewController:newController animated:YES];
  } else {
    UIViewController *viewController =
        [_dataSource directoryContentsController:self viewControllerWithFilePaths:newPaths];
    if (viewController) {
      [self.navigationController pushViewController:viewController animated:YES];
    }
  }
}

@end
