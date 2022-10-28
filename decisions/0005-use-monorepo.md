---
status: accepted
date: 2022-10-27
deciders: Brandyn Bennett
consulted:
informed:
---
# Use Monorepo

## Context and Problem Statement

There are multiple Elixir libraries involved with working in the Polyn ecosytem. It's faster to iterate when they're all in one place

## Decision Drivers

* Faster productivity
* Clear boundaries
* Atomic changes

## Considered Options

* Polyrepo
* Monorepo

## Decision Outcome

Chose to do a monorepo for Elixir libraries related to Polyn. Will be publishing each to Hex as if it were in its own codebase so that each package can be used independently.

### Positive Consequences

* Don't have to hop around between multiple codebases and deal with separate version control
* The projects are all related and it will be easier to move them forward together this way
* Less likely to forget a project when an update happens

### Negative Consequences

* May be increased temptations to cross some boundaries

## Validation

Should be able to be more productive in moving the Polyn libraries forward without tight coupling

## Pros and Cons of the Options

### Polyrepo

Keep each library in own repository

* Pro, clear separation
* Pro, no temptation to blur lines
* Con, slower to iterate
* Con, harder to see the big picture in one place
