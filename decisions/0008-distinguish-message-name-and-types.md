---
status: accepted
date: Oct 31, 2022
deciders: Brandyn Bennett
consulted:
informed:
---
# Distinguish Message Name and Types

## Context and Problem Statement

We need a clear term for how we identify messages. Related to [0006](0006-distinguish-events-and-messages.md). An event is a message, but a message isn't necessarily an event. We've been calling all messages "events" to this point and saying that each "event" has a "type". Saying each message has a "type" is confusing because you could be referring to the name of the message (e.g. "user.updated.v1") or the "kind" of message it is (e.g. "event", "query", "command"). We want to distinguish between types of messages and we also want to identify each message with a schema.

## Decision Drivers

* Clarity
* Common Language
* Developer Experience

## Considered Options

* Identify message with "type"
* Identify message with "name"

## Decision Outcome

We will say that each message has a "name". The "message name" should correspond to a matching schema. We will reserve "message type" to refer to subclasses of a message such as Events, Commands, and Queries.

### Positive Consequences

* The difference between messages and events will stay clear

### Negative Consequences

* We will have to update the protocol and code

## Validation

It will be clear in the code and docs the difference between messages and events