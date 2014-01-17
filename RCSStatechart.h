//
//  RCSPushdownState.h
//  RCSFSM
//
//  Created by Jim Roepcke on 2013-05-29.
//  Copyright (c) 2013 Roepcke Computing Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RCSPushdownState;

@protocol RCSPushdownStateContext <NSObject>

@property (nonatomic, weak) id<RCSPushdownState> state;

- (void)_stateContextDidEnterErrorState;

- (id<RCSPushdownState>)pushState;
- (id<RCSPushdownState>)popState;

@end

@protocol RCSPushdownState <NSObject>

// access singleton instance
+ (id<RCSPushdownState>)state;
- (id<RCSPushdownState>)startState;

- (NSString *)displayNameExcludedPrefix; // remove this prefix from the class name to derive the default displayName
- (NSString *)displayName; // class name, sans prefix from displayNameExcludedPrefix

- (BOOL)shouldLogTransitions; // returns NO by default

- (BOOL)shouldTellContextDidEnterErrorState; // returns YES by default
- (id<RCSPushdownState>)errorState;

// called by transition:to: just after the context's state is set to this state
- (void)enter:(id<RCSPushdownStateContext>)context;

// set's the context's state to the specified state, then calls -enter: on the specified state
- (void)transition:(id<RCSPushdownStateContext>)context to:(id<RCSPushdownState>)state;

// call this before transitioning to your FSM's Error state
- (void)logStateTransitionError:(SEL)sel forContext:(id<RCSPushdownStateContext>)context;

- (id<RCSPushdownState>)stateNamed:(NSString *)name;
- (id<RCSPushdownState>)declareErrorState:(id<RCSPushdownState>)errorState;
- (id<RCSPushdownState>)declareStartState:(id<RCSPushdownState>)startState;

- (SEL)transitionToErrorStateWhen:(SEL)selector;
- (void)whenEnteringPerform:(SEL)action;
- (SEL)doNothingWhen:(SEL)selector;
- (SEL)when:(SEL)selector perform:(SEL)action;
- (SEL)when:(SEL)selector transitionTo:(id<RCSPushdownState>)state;
- (SEL)when:(SEL)selector transitionTo:(id<RCSPushdownState>)state after:(SEL)action;
- (SEL)when:(SEL)selector transitionTo:(id<RCSPushdownState>)state before:(SEL)action;
- (SEL)when:(SEL)selector transitionTo:(id<RCSPushdownState>)state before:(SEL)postAction after:(SEL)preAction;

- (void)transition:(id<RCSPushdownStateContext>)context push:(id<RCSPushdownState>)state;
- (void)pop:(id<RCSPushdownStateContext>)context;

- (SEL)when:(SEL)selector push:(id<RCSPushdownState>)state;
- (SEL)when:(SEL)selector push:(id<RCSPushdownState>)state after:(SEL)action;
- (SEL)when:(SEL)selector push:(id<RCSPushdownState>)state before:(SEL)action;
- (SEL)when:(SEL)selector push:(id<RCSPushdownState>)state before:(SEL)postAction after:(SEL)preAction;

- (SEL)popWhen:(SEL)selector;
- (SEL)popWhen:(SEL)selector after:(SEL)action;
- (SEL)popWhen:(SEL)selector before:(SEL)action;
- (SEL)popWhen:(SEL)selector before:(SEL)postAction after:(SEL)preAction;

@end

@interface RCSBasePushdownState: NSObject <RCSPushdownState>

@end
