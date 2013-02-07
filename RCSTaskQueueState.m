//
//  RCSTaskQueueState.m
//  Created by Jim Roepcke.
//  See license below.
//

#import "RCSTaskQueueState.h"
#import "RCSTaskQueue.h"

@interface RCSTaskQueue (RCSTaskQueueStatePrivate)

- (void)_error;
- (void)_wake;
- (void)_enqueueTask:(RCSTask *)task;
- (void)_start;
- (void)_pause;
- (void)_resume;
- (void)_background;
- (void)_foreground;
- (void)_taskCancelled:(RCSTask *)task;
- (BOOL)_isEmpty;
- (void)_dequeue;

@end

@implementation RCSTaskQueueState

+ (id<RCSTaskQueueState>)state
{
    return (id<RCSTaskQueueState>)[super state];
}

- (NSString *)displayName
{
    NSString *className = NSStringFromClass([self class]);
    return [className substringFromIndex:[@"RCSTaskQueueState" length]];
}

- (void)wake:(RCSTaskQueue *)taskQueue
{
    RCSLogFSMAction(taskQueue);
    [taskQueue _wake];
}

- (void)enqueueTask:(RCSTask *)task forTaskQueue:(RCSTaskQueue *)taskQueue
{
    [self logStateTransitionError:_cmd forContext:taskQueue];
    [self error:taskQueue];
}

- (void)taskCancelled:(RCSTask *)task forTaskQueue:(RCSTaskQueue *)taskQueue;
{
    [self logStateTransitionError:_cmd forContext:taskQueue];
    [self error:taskQueue];
}

- (void)dequeueTask:(RCSTask *)task forTaskQueue:(RCSTaskQueue *)taskQueue
{
    [self logStateTransitionError:_cmd forContext:taskQueue];
    [self error:taskQueue];
}

- (void)empty:(RCSTaskQueue *)taskQueue
{
    [self logStateTransitionError:_cmd forContext:taskQueue];
    [self error:taskQueue];
}

- (void)pause:(RCSTaskQueue *)taskQueue
{
    [self logStateTransitionError:_cmd forContext:taskQueue];
    [self error:taskQueue];
}

- (void)resume:(RCSTaskQueue *)taskQueue
{
    [self logStateTransitionError:_cmd forContext:taskQueue];
    [self error:taskQueue];
}

- (void)background:(RCSTaskQueue *)taskQueue
{
    // nothing
    RCSLogFSMAction(taskQueue);
}

- (void)foreground:(RCSTaskQueue *)taskQueue
{
    // nothing
    RCSLogFSMAction(taskQueue);
}

- (void)error:(RCSTaskQueue *)taskQueue
{
    [self transition:taskQueue to:[RCSTaskQueueStateError state]];
}

@end

/*
 *
 * Concrete States
 *
 */

@implementation RCSTaskQueueStateError

- (void)enter:(RCSTaskQueue *)taskQueue
{
    [super enter:taskQueue];
    [taskQueue _error];
}

@end

@implementation RCSTaskQueueStateEmpty

- (void)enqueueTask:(RCSTask *)task forTaskQueue:(RCSTaskQueue *)taskQueue
{
    RCSLogFSMActionInput(taskQueue, task);
    [taskQueue _enqueueTask:task];
    [self transition:taskQueue to:[RCSTaskQueueStateNotEmpty state]];
    [taskQueue _start];
}

- (void)pause:(RCSTaskQueue *)taskQueue
{
    RCSLogFSMAction(taskQueue);
    [self transition:taskQueue to:[RCSTaskQueueStatePausedEmpty state]];
}

@end

@implementation RCSTaskQueueStatePausedEmpty

- (void)enqueueTask:(RCSTask *)task forTaskQueue:(RCSTaskQueue *)taskQueue
{
    RCSLogFSMActionInput(taskQueue, task);
    [task pause];
    [taskQueue _enqueueTask:task];
    [self transition:taskQueue to:[RCSTaskQueueStatePausedNotEmpty state]];
}

- (void)resume:(RCSTaskQueue *)taskQueue
{
    RCSLogFSMAction(taskQueue);
    [self transition:taskQueue to:[RCSTaskQueueStateEmpty state]];
}

@end

@implementation RCSTaskQueueStateNotEmpty

- (void)empty:(RCSTaskQueue *)taskQueue
{
    RCSLogFSMAction(taskQueue);
    [self transition:taskQueue to:[RCSTaskQueueStateEmpty state]];
}

- (void)enqueueTask:(RCSTask *)task forTaskQueue:(RCSTaskQueue *)taskQueue
{
    RCSLogFSMActionInput(taskQueue, task);
    [taskQueue _enqueueTask:task];
}

- (void)taskCancelled:(RCSTask *)task forTaskQueue:(RCSTaskQueue *)taskQueue;
{
    RCSLogFSMActionInput(taskQueue, task);
    [taskQueue _taskCancelled:task];
    if ([taskQueue _isEmpty])
    {
        [self empty:taskQueue];
    }
}

- (void)dequeueTask:(RCSTask *)task forTaskQueue:(RCSTaskQueue *)taskQueue
{
    RCSLogFSMActionInput(taskQueue, task);
    [taskQueue _dequeue];
    if ([taskQueue _isEmpty])
    {
        [self empty:taskQueue];
    }
    else
    {
        [taskQueue _start];
    }
}

- (void)pause:(RCSTaskQueue *)taskQueue
{
    RCSLogFSMAction(taskQueue);
    [taskQueue _pause];
    [self transition:taskQueue to:[RCSTaskQueueStatePausedNotEmpty state]];
}

- (void)background:(RCSTaskQueue *)taskQueue
{
    RCSLogFSMAction(taskQueue);
    [taskQueue _background];
    [self transition:taskQueue to:[RCSTaskQueueStateBackgroundedNotEmpty state]];
}

@end

@implementation RCSTaskQueueStatePausedNotEmpty

- (void)empty:(RCSTaskQueue *)taskQueue
{
    RCSLogFSMAction(taskQueue);
    [self transition:taskQueue to:[RCSTaskQueueStatePausedEmpty state]];
}

- (void)enqueueTask:(RCSTask *)task forTaskQueue:(RCSTaskQueue *)taskQueue
{
    RCSLogFSMActionInput(taskQueue, task);
    [task pause];
    [taskQueue _enqueueTask:task];
}

- (void)taskCancelled:(RCSTask *)task forTaskQueue:(RCSTaskQueue *)taskQueue;
{
    RCSLogFSMActionInput(taskQueue, task);
    [taskQueue _taskCancelled:task];
    if ([taskQueue _isEmpty])
    {
        [self empty:taskQueue];
    }
}

- (void)resume:(RCSTaskQueue *)taskQueue
{
    RCSLogFSMAction(taskQueue);
    [self transition:taskQueue to:[RCSTaskQueueStateNotEmpty state]];
    [taskQueue _resume];
}

@end

@implementation RCSTaskQueueStateBackgroundedNotEmpty

- (void)wake:(RCSTaskQueue *)taskQueue
{
    RCSLogFSMAction(taskQueue);
    [self transition:taskQueue to:[RCSTaskQueueStateNotEmpty state]];
    [taskQueue _wake];
}

- (void)foreground:(RCSTaskQueue *)taskQueue
{
    RCSLogFSMAction(taskQueue);
    [self transition:taskQueue to:[RCSTaskQueueStateNotEmpty state]];
    [taskQueue _foreground];
}

@end

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
