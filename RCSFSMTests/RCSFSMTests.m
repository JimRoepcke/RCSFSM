//
//  RCSFSMTests.m
//  RCSFSMTests
//
//  Created by Jim Roepcke on 2013-05-19.
//  Copyright (c) 2013 Roepcke Computing Solutions. All rights reserved.
//

#import "RCSFSMTests.h"
#import "RCSState.h"
#import "RCSStatechart.h"

@class TestContext;

@interface TestState : RCSBaseState

@end

@interface TestPushdownState : RCSBasePushdownState

@end

@implementation TestState

@end

@implementation TestPushdownState

@end

@interface TestState (Transitions)

- (void)start:(TestContext *)context;
- (void)gotoA:(TestContext *)context;

@end

@interface TestContext : NSObject <RCSStateContext>

@property (nonatomic, weak) TestState *state;
@property (nonatomic, assign) BOOL enteredStateA;

@end


@interface TestPushdownStateContext : NSObject <RCSPushdownStateContext>

@property (nonatomic, weak) TestPushdownState *state;
@property (nonatomic, strong) NSMutableArray *pushdownStack;
@property (nonatomic, assign) BOOL enteredSubA;

@end

@implementation TestContext

- (id)init
{
    self = [super init];
    if (self)
    {
        _state = [[TestState state] startState];
    }
    return self;
}

- (void)_stateContextDidEnterErrorState
{
    [NSException raise:NSInternalInconsistencyException format:@"TestContext did enter error state"];
}

- (void)_enteringStateA
{
    self.enteredStateA = YES;
}

@end

@implementation TestPushdownStateContext

- (id)init
{
    self = [super init];
    if (self) {
        _state = [[TestPushdownState state] startState];
        _pushdownStack = [NSMutableArray new];
    }
    return self;
}

- (id<RCSPushdownState>)pushState
{
    id<RCSPushdownState> result = self.state;
    if (result) [_pushdownStack addObject:result];
    return result;
}

- (id<RCSPushdownState>)popState
{
    id<RCSPushdownState> result = [_pushdownStack lastObject];
    if (result) [_pushdownStack removeLastObject];
    return result;
}

- (void)_enteringSubA
{
    self.enteredSubA = YES;
}

- (void)_stateContextDidEnterErrorState
{
    [NSException raise:NSInternalInconsistencyException format:@"TestPushdownStateContext did enter error PushdownState"];
}

@end

@implementation RCSFSMTests
{
    TestContext *_ctx;
    TestPushdownStateContext *_pushdownStateCtx;
}

+ (void)initialize
{
    if (self == [RCSFSMTests class])
    {
        id <RCSState> Base = [TestState state];
        id <RCSState> Error = [Base stateNamed:@"Error"];
        id <RCSState> Start = [Base stateNamed:@"Start"];
        id <RCSState> Running = [Base stateNamed:@"Running"];
        id <RCSState> StateA = [Base stateNamed:@"StateA"];
        id <RCSState> StateB = [Base stateNamed:@"StateB"];

        [Base declareErrorState:Error];
        [Base declareStartState:Start];

        SEL start = [Base transitionToErrorStateWhen:@selector(start:)];
        [Start when:start transitionTo:Running];

        SEL gotoA = [Running when:@selector(gotoA:) transitionTo:StateA];

        [StateA whenEnteringPerform:@selector(_enteringStateA)];

        id <RCSPushdownState> PushdownStateBase = [TestPushdownState state];
        id <RCSPushdownState> PushdownStateError = [PushdownStateBase stateNamed:@"Error"];
        id <RCSPushdownState> PushdownStateStart = [PushdownStateBase stateNamed:@"Start"];

        id <RCSPushdownState> PushdownStateSubA = [PushdownStateBase stateNamed:@"SubA"];

        [PushdownStateBase declareErrorState:PushdownStateError];
        [PushdownStateBase declareStartState:PushdownStateStart];

        [PushdownStateSubA whenEnteringPerform:@selector(_enteringSubA)];
    }
}

- (void)setUp
{
    [super setUp];
    _ctx = [[TestContext alloc] init];
    _pushdownStateCtx = [[TestPushdownStateContext alloc] init];
}

- (void)tearDown
{
    // Tear-down code here.
    _pushdownStateCtx = nil;
    _ctx = nil;
    [super tearDown];
}

- (void)testInitialize
{
    STAssertNotNil(NSClassFromString(@"TestStateStart"), @"Start state class not found");
    STAssertEquals([[TestState state] stateNamed:@"Start"], [[TestState state] startState], @"start state not set");
    STAssertEquals([[TestState state] stateNamed:@"Start"], [[[TestState state] stateNamed:@"Start"] startState], @"start state not set");

    STAssertEquals([[TestState state] stateNamed:@"Error"], [[TestState state] errorState], @"error state not set on Base state");
    STAssertEquals([[TestState state] stateNamed:@"Error"], [[[TestState state] stateNamed:@"Start"] errorState], @"error state not set on Start state");
}

- (void)testInit
{
    STAssertNotNil(_ctx, @"context doesn't exist");
    STAssertEquals([_ctx state], [[TestState state] startState], @"context should start in the Start state");
}

- (void)testTransition
{    
    [_ctx.state transition:_ctx to:[[TestState state] stateNamed:@"StateB"]];
    STAssertEquals(_ctx.state, [[TestState state] stateNamed:@"StateB"], nil);
}

- (void)testTransitionStartToRunning
{
    [_ctx.state start:_ctx];
    STAssertEquals([_ctx state], [[TestState state] stateNamed:@"Running"], @"context should start in the Running state");
}

- (void)testStateContextDidEnterErrorState
{
    [_ctx.state start:_ctx];
    // the Running state doesn't implement the start: transition, so it should run the base implementation with transitions to Error
    // the context class implements _stateContextDidEnterErrorState which throws an exception
    STAssertThrows([_ctx.state start:_ctx], @"start from Running should transition to error state, which should throw an exception");
}

- (void)testWhenEnteringPerform
{
    [_ctx.state start:_ctx];
    [_ctx.state gotoA:_ctx];
    STAssertTrue(_ctx.enteredStateA, nil);
}

- (void)testPush
{
    [_pushdownStateCtx.state transition:_pushdownStateCtx push:[[TestPushdownState state] stateNamed:@"SubA"]];
    STAssertEquals(_pushdownStateCtx.state, [[TestPushdownState state] stateNamed:@"SubA"], nil);
    STAssertEquals([_pushdownStateCtx.pushdownStack count], (NSUInteger)1, nil);
    STAssertEquals([_pushdownStateCtx.pushdownStack lastObject], [[TestPushdownState state] startState], nil);
    STAssertTrue(_pushdownStateCtx.enteredSubA, nil);
}

- (void)testPop
{
    [_pushdownStateCtx.state transition:_pushdownStateCtx push:[[TestPushdownState state] stateNamed:@"SubA"]];
    [_pushdownStateCtx.state pop:_pushdownStateCtx];
    STAssertEquals([_pushdownStateCtx.pushdownStack count], (NSUInteger)0, nil);
    STAssertEquals(_pushdownStateCtx.state, [[TestPushdownState state] startState], nil);
}

@end
