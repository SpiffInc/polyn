---
status: superseded by [ADR-0015](0015-polyn-focuses-on-message-validation.md)
date: 2022-10-26
deciders: Brandyn Bennett
consulted:
informed:
---
# Decentralize Read Models

## Context and Problem Statement

Need to decide how read models should work for querying. The Polyn Event Store is intended to separate reads from writes on a distributed network. If the writes go to the event store as the source of truth how do services on the network read the data?

## Decision Drivers

* Autonomy and flexilibility for each service
* High availability of the system
* High query performance

## Considered Options

* Lightweight "live" projections in the event store
* Each service manages own read model

## Decision Outcome

Each service manages own read model

We are assuming a microservice architecture for the Polyn Event Store where services are already going to be in place that need to share data. A large part of Polyn's purpose is to create loosely coupled, reliable, highly available services. Allowing each service to control how to store and structure its queryable data gives them full flexibility and autonomy to make the read model work the best way for its use case.

### Positive Consequences

* Each service can choose how to structure its read model without affecting any other service
* Each service will have the data it needs to perform and will able to operate independently of failures in other services
* Teams will be able to develop services without needing to download and run other services
* Read models can be destroyed and rebuilt without affecting the source data in the write model

### Negative Consequences

* Events will need to be passed to each service through a message broker which could result in multiple places to get events (event store and broker). This may be avoidable if services can subscribe directly to event store (event store).
* An "outbox" pattern may be necessary to ensure no disparity between message broker and even store
* It could take a long time to rebuild all the data in a new read model if lots of data is out there
* Catching up could be difficult as new data is coming into the write model while new data is publishing
* Will make strong consistency harder knowing when all the read models on the various services are caught-up

## Validation

Each service has an easy, low-friction, well documented way to populate their own read model from the event store. Edge cases, performance concerns are addressed and baked into the solution.

## Pros and Cons of the Options

### Lightweight "live" projections in the event store

Each service connects directly to the event store and queries live projections there. A service would connect to the EventStore and execute a query that builds up a view on the fly.

* Pro, Don't have to transport events to other services
* Pro, Deployment of write and read go together
* Pro, Always immediate consistency

* Con, Could become a performance and memory problem if there are lots of big event streams
* Con, event store service having to worry about scaling for writes and reads
* Con, less decoupled

https://www.eventstore.com/blog/live-projections-for-read-models-with-event-sourcing-and-cqrs
