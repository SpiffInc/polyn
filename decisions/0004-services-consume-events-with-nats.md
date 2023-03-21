---
status: superseded by [ADR-0015](0015-polyn-focuses-on-message-validation.md)
date: 2022-10-26
deciders: Brandyn Bennett
consulted:
informed:
---
# Services Consume Events With NATS

## Context and Problem Statement

We decided in [ADR 0002](./0002-decentralize-read-models.md) that each service will manage its own read model and they will be decentralized. What communication mechanism do the events use to build the read model?

## Decision Drivers

* Fast communication
* Consistency
* Maintainability
* Autonomous services

## Considered Options

* Services use client libraries to consume directly from eventstore
* Services consume events through an intermediary message broker

## Decision Outcome

Services will consume events through an intermediary message broker. Every event will be published to a NATS Stream that services can consume.

### Positive Consequences

* NATS is built for messaging and is more robust at that, event stores are not
* Decouples event store implementation from other services

### Negative Consequences

* Have to implement some kind of outbox pattern to ensure stuff in the eventstore got into NATS
* Indirect and will create additional communication layer maintenance
* Opens door for services publishing messages as events and skipping the event store

## Validation

Each service will be able to subscribe to a NATS stream to get all the events it cares about

## Pros and Cons of the Options

### Services use client libraries to consume directly from eventstore

* Pro, direct line to source-of-truth
* Pro, part of eventstoredb
* Pro, no communication layer maintence
* Con, couples services to event store
* Con, couple services to event store technology choice (Eventstoredb, postgres, etc)
