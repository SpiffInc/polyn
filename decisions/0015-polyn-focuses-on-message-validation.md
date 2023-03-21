---
status: accepted
date: 2023-01-25
deciders: Brandyn Bennett
consulted: Kobi Eshun
informed:
---
# Polyn Focuses on Message Validation

## Context and Problem Statement

Originally Polyn was intended to solve all the problems of an event-driven system and be an entire framework for [reactive services](https://www.reactivemanifesto.org/). It also tried to work with any message broker, but decided to focus on NATS when that became unweildy. Trying to solve all the problems of event-driven architecture is a tall order and may not be reasonable to do with Polyn.

## Decision Drivers

* Maintainability
* Focus
* Quality

## Considered Options

* Do all the things
* Focus on Message Validation

## Decision Outcome

Focus on Message Validation.

NATS is a message broker. It is good at pub/sub and reliable delivery of messages. NATS lacks schema structure for messages. There is a lot of work to do and things to consider for adding schemas to the messaging system. Polyn will refocus to only do that work.

### Positive Consequences

* The scope of what Polyn does will be clearer and easier to explain
* The code will be easier to maintain and ensure it does its job well
* Polyn won't try and force NATS to do something it wasn't designed for (event sourcing)

### Negative Consequences

* Engineers will not get all their event-driven needs solved in one place

## Pros and Cons of the Options

### Do all the things

Polyn will be a full event-driven system including persisting events and replaying them on different services.

* Pro, Only one place to look
* Con, NATS not designed for event storage and the concerns involved.
