---
status: accepted
date: 2023-03-23
deciders: Brandyn Bennett, Kobi Eshun
consulted:
informed:
---
# Migration Style Stream Management

## Context and Problem Statement

As discussed in [ADR 0016](./0016-decentralized-stream-management.md), each project will own the configuration for streams and consumers in a decentralized way. How should they do that?

## Decision Drivers

* Development Experience
* Consistency
* Robustness

## Considered Options

* Declarative config files
* Migration files

## Decision Outcome

Use migration files and a task to execute them. This will mimic database migrations in Elixir Ecto, and Ruby on Rails

### Positive Consequences

* Many developers have seen this pattern before
* We have an immutable log to see the history of the changes
* We can still construct the current state if we need to, but can't go the other way around
* Can delete consumers/streams in an intuitive way

### Negative Consequences

* Don't see all the state in one place as simply
