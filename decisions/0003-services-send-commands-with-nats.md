---
status: superseded by [ADR-0015](0015-polyn-focuses-on-message-validation.md)
date: 2022-10-26
deciders: Brandyn Bennett
consulted:
informed:
---
# Services Send Commands Over NATS

## Context and Problem Statement

We want a central service that manages the event store. What communication mechanism do we use to send commands from other services to the event store?

## Decision Drivers

* We want events in the store to be valid
* We want command validation logic centralized

## Considered Options

* Services write directly to event store
* Services send commands over NATS

## Decision Outcome

Services send commands over NATS

Using NATS to communicate Command messages ensures that only valid events will be stored

### Positive Consequences

* Loose coupling between services and event store
* Loose coupling between event store technology choice (eventstoredb, postgres, etc)
* Each service doesn't have to rewrite validation logic for an aggregate/command

### Negative Consequences

* More indirect, have to work with communication tech as well as storage tech
* Have to figure out how to juggle performance, ordering, consumers, etc

## Validation

Each service will be able to use Polyn to publish a command message. The message will be validated when published and when consumed by the Event Store Service. Each Command message will need a schema that is added to the POLYN_SCHEMAS key-value store. Each Command will need handling code in the Event Store Service.

## Pros and Cons of the Options

### Services write directly to event store

* Pro, Less indirection and no need to manage more communication technology
* Con, There is no separation of the event store and the other services.
* Con, Services are coupled to event store technology choice
* Con, Each service has to implement validation logic for the command before writing