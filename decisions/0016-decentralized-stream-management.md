---
status: accepted
date: 2023-03-21
deciders: Brandyn Bennett, Kobi Eshun
consulted:
informed:
---
# Decentralized Stream Management

## Context and Problem Statement

The first draft of Polyn had centralized model with streams being managed in a central repository via terraform and a cli tool. Would it be better to allow teams to own their stream configuration in their own projects?

## Decision Drivers

* Autonomy
* Development Experience
* Development Efficiency
* Discoverability

## Considered Options

* Manage streams centrally
* Decentralize stream management

## Decision Outcome

Decentralize Stream Management. The client libraries will create streams and consumers based on configuration in the application's codebase. It will be assumed that one given project/team will own a certain stream and its management.

### Positive Consequences

* engineers don't have to leave their existing codebase to manage streams
* additional tools like a cli and/or terraform won't be necessary
* stream management will be closer to team and project that manages it

### Negative Consequences

* There won't be one codebase to see all the streams
* Will need a way to make streams discoverable for local development

