# Report

elixir go reeee

## Design and Implementation (~1page)

We used type annotations wherever we could in order to enhance readability and have `mix` provide us with additional information to catch bugs earlier on.

### Ballots

In order to represent ballots that can be ordered but still hold their leader's PID, we initially set out to order ballots by hashing the string representation of their PIDs. We later found that two different PIDs may have the same string representation, effetively making leaders _not_ totally ordered. Instead, we adopt an approach where a ballot is a tuple of three (rather than two) elements: $<b_{number}, \texttt{server\_num}, process_{id}>$. We then only use the ballot number $b_{number}$ and the node id $\texttt{server\_num}$ to lexicographically order ballots.

### Data Structures

To store proposals, we use `Map`s for efficient $O(1)$ membership check operations. For other state, we use `MapSet`s.

### Liveness

TODO

## Debugging and Testing Methodology (~1/2 pages)

We extended `Monitor` by adding a _active leaders_ field. Particularly useful in testing liveliness, and determining when a slow system is 'stuck'.

We use a `Util.log()` helper function extensively, which takes a 'debug level' atom which serves as logging instrumentation for the application. In order to easily debug to what processes the messages get passed around, we always print the `node_num` and the type of process in question (Scout, Acceptor, etc) before every message.

We also wrote a testing suite that unit tests our implementation.

## Correctness of the System

TODO how on earth do we do this wtf 2.5 pages????

### Environment

Linux :)))) 

## Outpus and Interesting Findings

TODO

## Diagrams and Requests Flow

TODO (~1 page)



