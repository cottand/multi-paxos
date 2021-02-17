# Report

Nicolas D'Cotta (nd3018) and William Profit (wtp18)
6009 Distributed Algorithms 
Coursework

## Design and Implementation (~1page)

We followed the design outlined in the paper "Paxos Made Moderately Complex"
by Robbert Van Renesse and Deniz Altinbuken with a few modifications.

Most notably we make use of a collapsed architecture where a server process
hosts one replica, one acceptor, one leader and one database. This allows for
a simpler design while still ensuring correctness of the algorithm. The
server and client processes initially get spawned by the over arching
multipaxos process which deals with bootstrapping the system.

We used type annotations wherever we could in order to enhance readability
and have `mix` provide us with additional information to catch bugs earlier
on.

### Ballots

In order to represent ballots that can be ordered but still hold their
leader's PID, we initially set out to order ballots by hashing the string
representation of their PIDs. We later found that two different PIDs may have
the same string representation, effetively making leaders _not_ totally
ordered. Instead, we adopt an approach where a ballot is a tuple of three
(rather than two) elements: $<b_{number}, \texttt{server\_num},
process_{id}>$. We then only use the ballot number $b_{number}$ and the node
id $\texttt{server\_num}$ to lexicographically order ballots.

### Data Structures

To store proposals, we use `Map`s for efficient $O(1)$ membership check
operations. For other states, we use `MapSet`s.

For more complex modules like `replica`, we encapsulate all the member
variables into a `state` dictionary that gets updated and passed around.

### Liveness

To implement liveness, we chose to have leaders enter a 'pinging mode' when
they get preemted. In this 'pinging mode', they send a `:ping` message to the
leader that preempted them (ever $t_{ping}$ ms, for example). All leaders
sytematically reply `:pong` to every `:ping` request. Therefore, when a
leader $\lambda$ gets preempted by another leader $\lambda'$, $\lambda$ will
become inactive until $\lambda'$ becomes faulty (ie, until $\lambda'$ stops
replying `:pong`).

#### Choosing $t_{ping}$

$t_{ping}$ corresponds to both the pinging timeout (how long we should wait
for a `:pong` message before considering the replica we are waiting for as
dead), and to the interval between each `:ping` request.

Therefore, $t_{ping}$ must be large enough that the replica has time to
reply, but small enough that a faulty replica can be preempted quickly. In
our current domain of a banking app, we chose a delay of 200ms.

## Debugging and Testing Methodology (~0.5 pages)

We extended `Monitor` by adding an _active leaders_ field. Particularly
useful in testing liveliness, and determining when a slow system is 'stuck'.

We use a `Util.log()` helper function extensively, which takes a 'debug
level' atom which serves as logging instrumentation for the application. In
order to easily debug to what processes the messages get passed around, we
always print the `node_num` and the type of process in question (Scout,
Acceptor, etc) before every message.

We also wrote a testing suite that unit tests for certain modules of our
implementation. This has allowed us to be more confident in making changes as
we ensured we were not breaking things elsewhere. We were however not able to
unit test every module due to their nature which made then difficult to test.

## Correctness of the System

We have run our program under various scenarios, of which the outputs can be
found under the `outputs` directory.

We ran two experiments with 2 servers and 5 clients under low load, with and
without livelock prevention. The bulk of the experiment is done with 5
servers and 5 clients, tested under low, high and very high load, with and
without livelock prevention and also with and without a server crashing.

First off we notice that using 2 servers generally gives better performance
than using 5 servers. This is because it is to coordinate the leaders into
getting a majority with 2 leaders rather than 5, where more messages need to
get exchanged and more preemptions will occur. An other factor is that more
livelocking occurs with more servers (*I THINK????*).

Without livelock prevention we can almost manage low loads but then very
little work gets done under high and very high load. This is due to the fact
that under higher workloads, leaders are competing more to get their ballots
adopted so livelock occurs with a higher probability.

On the other hand, adding livelock prevention significantly improves
performance and reliability. We are able to manage high loads and even very
high loads although for the latter we encounter performance issues, where we
are making progress but not fast enough given the rate of incoming requests.
This is seen as the update rate lagging behind the request rate. However the
system is still correct and would eventually catch up if given the time to or
if ran with better performance.

When crashing a server, we notice that the behaviour of the system is not
affected, other servers continue serving clients as expected.

### Environment

The program was run uder MacOS on a 2019 16" MacBook Pro with a 2.6 GHz
6-Core Intel Core i7 CPU and 16 GB 2667 MHz DDR4 RAM.

## Outputs and Interesting Findings

*This might be repeating section "Correctness of the system?"*

## Diagrams and Requests Flow

TODO (~1 page)

### Lifecycle of a Client's `command`
...when a leader had been elected. Note how we can skip phase one (`:p1*` messages altoghether)
```sequence
Client->Replica: {:request cmd}
Replica->Leader: {:propose, slot, cmd}
Leader->Commander: spawns with\n<ballot, slot ,cmd>
Commander->Acceptor1: {:p2a, leader,\n{ballot, slot, cmd}}
Commander->AcceptorN: {:p2a, leader,\n{ballot, slot, cmd}}
Acceptor1->Commander: {:p2a, acceptor1, ballot}
AcceptorN->Commander: {:p2a, acceptorN, ballot}
Commander->Replica: {:decision, slot, ballot}
Replica->DB: {:EXECUTE, transaction}
Replica->Client: {:CLIENT_REPLY, cmd_id}
```