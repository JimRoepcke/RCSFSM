# RCSFSM

[Finite State Machines](http://en.wikipedia.org/wiki/Finite-state_machine) (FSM) and [Pushdown Automata](http://en.wikipedia.org/wiki/Pushdown_automaton) (PDA), modelled with Objective-C, using the GOF's [State Design pattern](http://en.wikipedia.org/wiki/State_pattern).

Initially developed for a project in a [graduate Distributed Systems course](http://web.uvic.ca/calendar2012/CDs/CSC/562.html), later refined in a [graduate Design Patterns](http://web.uvic.ca/calendar2012/CDs/CSC/578.html) course. Since then I've used this in commercial projects.

Better documentation will be provided as time allows, for now, here is a brief description of what you'll find here.

# Usage Requirements

This code requires ARC and is known to work with iOS 5.x and later in Xcode 4.5 and later.

---

# Finite State Machines

## &lt;RCSStateContext&gt; protocol

An object that has a current FSM state.

## &lt;RCSState&gt; protocol

A state in a FSM. `<RCSState>` objects are intended to be stateless, shared objects - [flyweights](http://en.wikipedia.org/wiki/Flyweight_pattern).

Define methods on your state objects that transition its `<RCSStateContext>` to another state.

## RCSBaseState class

Default implementation of the `<RCSState>` protocol.

---

# Pushdown Automata

## &lt;RCSPushdownContext&gt; protocol

An object that has a current PDA state.

## &lt;RCSPushdownState&gt; protocol

A state in a PDA. This is useful when you multiple states need to be able to transition to a single state, and that state needs to be able to "go back" to whichever one transitioned to it. Rather than having a combinatorial explosion in the number of states to facilitate this, things stay simple by pushing the common state and defining a transition that pops back.

Define methods on your pushdown state objects that transition and push its <RCSPushdownStateContext> to another pushdown state.

## RCSBasePushdownState class

Default implementation of the `<RCSPushdownState>` protocol.

---

# Example FSMs

## RCSTask &lt;RCSStateContext&gt;

Respresents a task that uses a FSM to coordinate itself - an alternative to `NSOperation` that you can use to model a complex multi-state process. This is provided an example, but it is quite useful and was written for a production iOS app.

### RCSTaskState : RCSBaseState

FSM states for a `RCSTask`.

##RCSTaskQueue &lt;RCSStateContext, RCSTaskDelegate&gt;

Represents a queue that undestands the semantics of `RCSTask` - a lightweight alternative to `NSOperationQueue`.

### RCSTaskQueueState : RCSBaseState

FSM states for a `RCSTaskQueue`.
