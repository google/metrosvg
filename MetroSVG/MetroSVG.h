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

// The umbrella header of MetroSVG. This file can be included by both C and
// Objective-C code.

#pragma once

#include <TargetConditionals.h>

#include "MetroSVG/Public/MSCDebug.h"
#include "MetroSVG/Public/MSCDocument.h"
#include "MetroSVG/Public/MSCStyleSheet.h"

#ifdef __OBJC__ 
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

#import "MetroSVG/iOS/MSVGDocument.h"
#import "MetroSVG/iOS/MSVGStyleSheet.h"

#endif  // TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#endif  // __OBJC__
