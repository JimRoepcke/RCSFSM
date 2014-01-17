//
//  RCSPushdownState.m
//  RCSFSM
//
//  Created by Jim Roepcke on 2013-05-29.
//  Copyright (c) 2013 Roepcke Computing Solutions. All rights reserved.
//

#import <objc/runtime.h>
#import <objc/message.h>
#import "RCSStatechart.h"

static NSUInteger RCSNumberOfArgumentsInSelector(SEL sel);
static NSUInteger RCSNumberOfArgumentsInSelector(SEL sel)
{
    NSString *selString = NSStringFromSelector(sel);
    CFStringRef selfAsCFStr = (__bridge CFStringRef)selString;

    CFStringInlineBuffer inlineBuffer;
    CFIndex length = CFStringGetLength(selfAsCFStr);
    CFStringInitInlineBuffer(selfAsCFStr, &inlineBuffer, CFRangeMake(0, length));

    NSUInteger counter = 0;

    for (CFIndex i = 0; i < length; i++) {
        UniChar c = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, i);
        if (c == (UniChar)':') counter += 1;
    }

    return counter;
}

@implementation RCSBasePushdownState

+ (id)state
{
	id<RCSPushdownState> result = objc_getAssociatedObject(self, @"sharedInstance");
	if (!result)
    {
		result = [[[self class] alloc] init];
		objc_setAssociatedObject(self, @"sharedInstance", result, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return result;
}

- (id<RCSPushdownState>)startState
{
    return nil;
}

- (NSString *)displayNameExcludedPrefix
{
    return nil;
}

- (NSString *)displayName
{
    NSString *className = NSStringFromClass([self class]);
    return [className substringFromIndex:[[self displayNameExcludedPrefix] length]];
}

- (BOOL)shouldLogTransitions
{
    return NO;
}

- (BOOL)shouldTellContextDidEnterErrorState
{
    return YES;
}

- (id<RCSPushdownState>)errorState
{
    return nil;
}

- (void)enter:(id<RCSPushdownStateContext>)context
{
    if ([self errorState] == self)
    {
        if ([self shouldTellContextDidEnterErrorState])
        {
            [context _stateContextDidEnterErrorState];
        }
    }
}

- (void)transition:(id<RCSPushdownStateContext>)context to:(id<RCSPushdownState>)state
{
    if ([self shouldLogTransitions])
    {
        NSLog(@"transition %@ to %@", context, [state displayName]);
    }
    [context setState:state];
    [state enter:context];
}

- (void)logStateTransitionError:(SEL)sel forContext:(id<RCSPushdownStateContext>)context
{
    NSLog(@"%@(%@): %@ is not a supported request", context, [self displayName], NSStringFromSelector(sel));
}

- (id<RCSPushdownState>)stateNamed:(NSString *)name
{
    NSString *baseName = NSStringFromClass([self class]);
    NSString *statechartClassName = [baseName stringByAppendingString:name];
    Class statechartClass = NSClassFromString(statechartClassName);
    if (!statechartClass)
    {
        statechartClass = objc_allocateClassPair([self class], [statechartClassName cStringUsingEncoding:NSASCIIStringEncoding], 0);
        objc_registerClassPair(statechartClass);
    }
    return [statechartClass state];
}

- (id<RCSPushdownState>)declareErrorState:(id<RCSPushdownState>)errorState
{
    if (errorState)
    {
        IMP imp = imp_implementationWithBlock(^(id<RCSPushdownState> _self) {
            return errorState;
        });
        class_addMethod([self class], @selector(errorState), imp, "v@:");
    }
    return errorState;
}

- (id<RCSPushdownState>)declareStartState:(id<RCSPushdownState>)startState
{
    if (startState)
    {
        IMP imp = imp_implementationWithBlock(^(id<RCSPushdownState> _self) {
            return startState;
        });
        class_addMethod([self class], @selector(startState), imp, "v@:");
    }
    return startState;
}

- (void)whenEnteringPerform:(SEL)action
{
    if (action && (RCSNumberOfArgumentsInSelector(action) == 0))
    {
        IMP imp = imp_implementationWithBlock(^(id<RCSPushdownState> _self, id<RCSPushdownStateContext> context) {
            struct objc_super objcSuper = {_self, [_self superclass]};
            objc_msgSendSuper(&objcSuper, @selector(enter:), context);
            objc_msgSend(context, action);
        });
        class_addMethod([self class], @selector(enter:), imp, "v@:@");
    }
}

- (SEL)transitionToErrorStateWhen:(SEL)selector
{
    switch (RCSNumberOfArgumentsInSelector(selector))
    {
        case 2:
        {
            IMP imp = imp_implementationWithBlock(^(id<RCSPushdownState> _self, id<RCSPushdownStateContext> context, id _) {
                [_self logStateTransitionError:selector forContext:context];
                id<RCSPushdownState> errorState = [_self errorState];
                if (errorState) [_self transition:context to:errorState];
            });
            class_addMethod([self class], selector, imp, "v@:@@");
            break;
        }
        case 1:
        default:
        {
            IMP imp = imp_implementationWithBlock(^(id<RCSPushdownState> _self, id<RCSPushdownStateContext> context) {
                [_self logStateTransitionError:selector forContext:context];
                id<RCSPushdownState> errorState = [_self errorState];
                if (errorState) [_self transition:context to:errorState];
            });
            class_addMethod([self class], selector, imp, "v@:@");
            break;
        }
    }
    return selector;
}

- (SEL)doNothingWhen:(SEL)selector
{
    return [self _declareTransition:selector preAction:(SEL)0 transitionTo:nil postAction:(SEL)0];
}

- (SEL)when:(SEL)selector perform:(SEL)action
{
    return [self _declareTransition:selector preAction:action transitionTo:nil postAction:(SEL)0];
}

- (SEL)when:(SEL)selector transitionTo:(id<RCSPushdownState>)state
{
    return [self _declareTransition:selector preAction:(SEL)0 transitionTo:state postAction:(SEL)0];
}

- (SEL)when:(SEL)selector transitionTo:(id<RCSPushdownState>)state after:(SEL)action
{
    return [self _declareTransition:selector preAction:action transitionTo:state postAction:(SEL)0];
}

- (SEL)when:(SEL)selector transitionTo:(id<RCSPushdownState>)state before:(SEL)action
{
    return [self _declareTransition:selector preAction:(SEL)0 transitionTo:state postAction:action];
}

- (SEL)when:(SEL)selector transitionTo:(id<RCSPushdownState>)state before:(SEL)postAction after:(SEL)preAction
{
    return [self _declareTransition:selector preAction:preAction transitionTo:state postAction:postAction];
}

- (SEL)_declareTransition:(SEL)selector preAction:(SEL)preAction transitionTo:(id<RCSPushdownState>)state postAction:(SEL)postAction
{
    switch (RCSNumberOfArgumentsInSelector(selector))
    {
        case 2:
        {
            IMP imp = imp_implementationWithBlock(^(id<RCSPushdownState> _self, id<RCSPushdownStateContext> context, id object) {
                if (preAction) objc_msgSend(context, preAction, object);
                if (state) [_self transition:context to:state];
                if (postAction) objc_msgSend(context, postAction, object);
            });
            class_addMethod([self class], selector, imp, "v@:@@");
            break;
        }
        case 1:
        default:
        {
            IMP imp = imp_implementationWithBlock(^(id<RCSPushdownState> _self, id<RCSPushdownStateContext> context) {
                if (preAction) objc_msgSend(context, preAction);
                if (state) [_self transition:context to:state];
                if (postAction) objc_msgSend(context, postAction);
            });
            class_addMethod([self class], selector, imp, "v@:@");
            break;
        }
    }
    return selector;
}

- (void)transition:(id<RCSPushdownStateContext>)context push:(id<RCSPushdownState>)state
{
    if ([self shouldLogTransitions])
    {
        NSLog(@"transition %@ push %@", context, [state displayName]);
    }
    [context pushState];
    [context setState:state];
    [state enter:context];
}

- (void)pop:(id<RCSPushdownStateContext>)context
{
    id<RCSPushdownState> state = [context popState];
    if ([self shouldLogTransitions])
    {
        NSLog(@"transition %@ pop %@", context, [state displayName]);
    }
    [context setState:state];
    [state enter:context];
}

- (SEL)when:(SEL)selector push:(id<RCSPushdownState>)state
{
    return [self _declareTransition:selector preAction:(SEL)0 push:state postAction:(SEL)0];
}

- (SEL)when:(SEL)selector push:(id<RCSPushdownState>)state after:(SEL)action
{
    return [self _declareTransition:selector preAction:action push:state postAction:(SEL)0];
}

- (SEL)when:(SEL)selector push:(id<RCSPushdownState>)state before:(SEL)action
{
    return [self _declareTransition:selector preAction:(SEL)0 push:state postAction:action];
}

- (SEL)when:(SEL)selector push:(id<RCSPushdownState>)state before:(SEL)postAction after:(SEL)preAction
{
    return [self _declareTransition:selector preAction:preAction push:state postAction:postAction];
}

- (SEL)_declareTransition:(SEL)selector preAction:(SEL)preAction push:(id<RCSPushdownState>)state postAction:(SEL)postAction
{
    switch (RCSNumberOfArgumentsInSelector(selector))
    {
        case 2:
        {
            IMP imp = imp_implementationWithBlock(^(id<RCSPushdownState> _self, id<RCSPushdownStateContext> context, id object) {
                if (preAction) objc_msgSend(context, preAction, object);
                if (state) [_self transition:context push:state];
                if (postAction) objc_msgSend(context, postAction, object);
            });
            class_addMethod([self class], selector, imp, "v@:@@");
            break;
        }
        case 1:
        default:
        {
            IMP imp = imp_implementationWithBlock(^(id<RCSPushdownState> _self, id<RCSPushdownStateContext> context) {
                if (preAction) objc_msgSend(context, preAction);
                if (state) [_self transition:context push:state];
                if (postAction) objc_msgSend(context, postAction);
            });
            class_addMethod([self class], selector, imp, "v@:@");
            break;
        }
    }
    return selector;
}

- (SEL)popWhen:(SEL)selector
{
    return [self _declarePop:selector preAction:(SEL)0 postAction:(SEL)0];
}

- (SEL)popWhen:(SEL)selector after:(SEL)action
{
    return [self _declarePop:selector preAction:action postAction:(SEL)0];
}

- (SEL)popWhen:(SEL)selector before:(SEL)action
{
    return [self _declarePop:selector preAction:(SEL)0 postAction:action];
}

- (SEL)popWhen:(SEL)selector before:(SEL)postAction after:(SEL)preAction
{
    return [self _declarePop:selector preAction:preAction postAction:postAction];
}

- (SEL)_declarePop:(SEL)selector preAction:(SEL)preAction postAction:(SEL)postAction
{
    switch (RCSNumberOfArgumentsInSelector(selector))
    {
        case 2:
        {
            IMP imp = imp_implementationWithBlock(^(id<RCSPushdownState> _self, id<RCSPushdownStateContext> context, id object) {
                if (preAction) objc_msgSend(context, preAction, object);
                [_self pop:context];
                if (postAction) objc_msgSend(context, postAction, object);
            });
            class_addMethod([self class], selector, imp, "v@:@@");
            break;
        }
        case 1:
        default:
        {
            IMP imp = imp_implementationWithBlock(^(id<RCSPushdownState> _self, id<RCSPushdownStateContext> context) {
                if (preAction) objc_msgSend(context, preAction);
                [_self pop:context];
                if (postAction) objc_msgSend(context, postAction);
            });
            class_addMethod([self class], selector, imp, "v@:@");
            break;
        }
    }
    return selector;
}

@end
