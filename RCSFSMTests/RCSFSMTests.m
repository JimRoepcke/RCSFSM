//
//  RCSFSMTests.m
//  RCSFSMTests
//
//  Created by Jim Roepcke on 2013-05-19.
//  Copyright (c) 2013 Roepcke Computing Solutions. All rights reserved.
//

#import "RCSFSMTests.h"
#import "RCSState.h"

@class TestContext;

@interface TestState : RCSBaseState

@end

@implementation TestState

@end

@interface TestState (Transitions)

- (void)start:(TestContext *)context;
- (void)gotoA:(TestContext *)context;

@end

@interface TestContext : NSObject <RCSStateContext>

@property (nonatomic, weak) TestState *state;
@property (nonatomic, assign) BOOL enteredStateA;

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

@implementation RCSFSMTests
{
    TestContext *_ctx;
}

+ (void)initialize
{
    if (self == [RCSFSMTests class])
    {
        id <RCSState> Base = [TestState state];
        id <RCSState> Error = [[TestState state] stateNamed:@"Error"];
        id <RCSState> Start = [[TestState state] stateNamed:@"Start"];
        id <RCSState> Running = [[TestState state] stateNamed:@"Running"];
        id <RCSState> StateA = [[TestState state] stateNamed:@"StateA"];
        id <RCSState> StateB = [[TestState state] stateNamed:@"StateB"];

        [Base declareErrorState:Error];
        [Base declareStartState:Start];

        SEL start = [Base transitionToErrorStateWhen:@selector(start:)];
        [Start when:start transitionTo:Running];

        SEL gotoA = [Running when:@selector(gotoA:) transitionTo:StateA];

        [StateA whenEnteringPerform:@selector(_enteringStateA)];
    }
}

- (void)setUp
{
    [super setUp];
    _ctx = [[TestContext alloc] init];
}

- (void)tearDown
{
    // Tear-down code here.
    
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

@end
