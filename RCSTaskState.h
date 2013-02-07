//
//  RCSTaskState.h
//  Created by Jim Roepcke.
//  See license below.
//

#import "RCSState.h"

#define RCSLogFSRCSnitialized(context) NSLog(@"%@(%@)", (context), [self.state displayName])
#define RCSLogFSMOwnsFSM(context, child) NSLog(@"%@(%@) owns %@(%@)", (context), [self.state displayName], (child), [child.state displayName])
#define RCSLogFSMEnterState(context) NSLog(@"%@(%@)", (context), [self displayName])
#define RCSLogFSMAction(context) NSLog(@"%@(%@): %@", (context), [self displayName], NSStringFromSelector(_cmd))
#define RCSLogFSMActionInput(context, input) \
    do \
    { \
        NSLog(@"%@(%@): %@", (context), [self displayName], NSStringFromSelector(_cmd)); \
        NSLog(@"input: %@", (input)); \
    } \
    while (0);
#define RCSLogFSMActionOutput(context, output) \
    do \
    { \
        NSLog(@"%@(%@): %@", (context), [self displayName], NSStringFromSelector(_cmd)); \
        NSLog(@"output: %@", (output)); \
    } \
    while (0);
#define RCSLogFSMActionInputOutput(context, input, output) \
    do \
    { \
        NSLog(@"%@(%@): %@", (context), [self displayName], NSStringFromSelector(_cmd)); \
        NSLog(@"input: %@", (input)); \
        NSLog(@"output: %@", (output)); \
    } \
    while (0);

@class RCSTask;

@protocol RCSTaskState <RCSState>

- (void)error:(RCSTask *)task;
- (void)cancel:(RCSTask *)task;
- (void)start:(RCSTask *)task;
- (void)wake:(RCSTask *)task;

- (void)pause:(RCSTask *)task;
- (void)resume:(RCSTask *)task;

- (void)foreground:(RCSTask *)task;
- (void)background:(RCSTask *)task;

@end

@interface RCSBaseTaskState : RCSBaseState
@end

@interface RCSTaskState : RCSBaseTaskState <RCSTaskState>

+ (id<RCSTaskState>)state;

@end

@interface RCSTaskStateError : RCSTaskState @end
@interface RCSTaskStateStart : RCSTaskState @end
@interface RCSTaskStateCancelled : RCSTaskState @end

/*
 * Copyright 2013 Jim Roepcke <jim@roepcke.com>. All rights reserved.
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */
