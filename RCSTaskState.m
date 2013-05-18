//
//  RCSTaskState.m
//  Created by Jim Roepcke.
//  See license below.
//

#import "RCSTaskState.h"
#import "RCSTask.h"

@implementation RCSBaseTaskState

- (void)transition:(id<RCSStateContext>)context to:(id<RCSState>)state
{
    NSLog(@"%@(%@): transition to %@", context, [self displayName], [state displayName]);
    [super transition:context to:state];
}

- (void)logStateTransitionError:(SEL)sel forContext:(id<RCSStateContext>)context
{
    NSLog(@"%@(%@): %@ is not a supported request", context, [self displayName], NSStringFromSelector(sel));
    NSLog(@"%@(%@): %@ is not a supported request", context, [self displayName], NSStringFromSelector(sel));
}

@end

@implementation RCSTaskState

+ (id<RCSTaskState>)state
{
    return (id<RCSTaskState>)[super state];
}

- (id<RCSTaskState>)errorState
{
    return [RCSTaskStateError state];
}

- (NSString *)displayName
{
    NSString *className = NSStringFromClass([self class]);
    return [className substringFromIndex:[@"RCSTaskState" length]];
}

- (void)error:(RCSTask *)task
{
    [self transition:task to:[task errorState]];
}

- (void)cancel:(RCSTask *)task
{
    [self transition:task to:[task cancelledState]];
}

- (void)start:(RCSTask *)task
{
    [self logStateTransitionError:_cmd forContext:task];
    [self error:task];
}

- (void)wake:(RCSTask *)task
{
    // nothing
    RCSLogFSMAction(task);
}

- (void)pause:(RCSTask *)task
{
    [self logStateTransitionError:_cmd forContext:task];
    [self error:task];
}

- (void)resume:(RCSTask *)task
{
    [self logStateTransitionError:_cmd forContext:task];
    [self error:task];
}

- (void)background:(RCSTask *)task
{
    // nothing
    RCSLogFSMAction(task);
}

- (void)foreground:(RCSTask *)task
{
    // nothing
    RCSLogFSMAction(task);
}

@end

/*
 *
 * Concrete States
 *
 */

@implementation RCSTaskStateError

@end

@implementation RCSTaskStateCancelled

- (void)enter:(RCSTask *)task
{
    [super enter:task];
    [task _cancelled];
}

@end

@implementation RCSTaskStateStart
// nothing
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
