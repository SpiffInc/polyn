---
status: accepted
date: 2022-11-03
deciders: Brandyn Bennett
consulted:
informed:
---
# Default Stream Replicas to One

## Context and Problem Statement

NATS Streams can have between 1 and 5 replicas. How many replicas should a stream have when it's created?

## Decision Drivers

* Resiliency
* Maintenance
* Developer experience

## Considered Options

* Dynamic replicas up to 3 based on cluster size
* Only do one

## Decision Outcome

Default to one replica. When a new stream is added and a stream is created from it will only have 1 replica

### Positive Consequences

* No extra code to dynamically find cluster size
* Simpler
* More relient on an event store as a source of truth
* Messaging is faster since replication is not part of the equation

### Negative Consequences

* If a NATS server goes down with the stream on it we will have to rebuild it somehow

## Validation

Each stream will have 1 replica

## Pros and Cons of the Options

### Dynamic replicas up to 3 based on cluster size

Will need to determine the cluster size and do anywhere between 1-3 replicas based on how many servers there are

* Pro, one NATS server crashing won't disrupt flow of events because a replica will be ready to go
* Con, All nodes could go down and we'd still have to deal with problem of rebuilding or restoring
* Con, Some systems may only have one node and so rebuilding/restoring may still come up
* Con, Message system becomes more relied on as a data source
