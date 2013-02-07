//
//  RCSState.m
//  Created by Jim Roepcke.
//  See license below.
//

#import <objc/runtime.h>

#import "RCSState.h"


@implementation RCSBaseState

+ (id) state
{
	RCSBaseState *result = objc_getAssociatedObject(self, @"sharedInstance");
	if (!result)
    {
		result = [[[self class] alloc] init];
		objc_setAssociatedObject(self, @"sharedInstance", result, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return result;
}

- (NSString *)displayName
{
    return NSStringFromClass([self class]);
}

- (void)enter:(id<RCSStateContext>)context
{
}

- (void)transition:(id<RCSStateContext>)context to:(id<RCSState>)state
{
    // LogDebug(@"transition %@ to %@", context, [state displayName]);
    [context setState:state];
    [state enter:context];
}

- (void)logStateTransitionError:(SEL)sel forContext:(id<RCSStateContext>)context
{
    NSLog(@"%@(%@): %@ is not a supported request", context, [self displayName], NSStringFromSelector(sel));
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
