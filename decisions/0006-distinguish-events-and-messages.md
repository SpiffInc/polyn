---
status: accepted
date: 2022-10-28
deciders: Brandyn Bennett
consulted:
informed:
---
# Distinguish Events and Messages

## Context and Problem Statement

There are related, but different concepts between a message and event. They've been getting used interchangeable and its causing confusion.

## Decision Drivers

* Making code match the model
* Consistency
* Clarity
* Ease of use

## Considered Options

* Keep conflating them
* Separate the concepts

## Decision Outcome

Separate the concepts.

Events can be messages, but messages aren't necessarily events. Polyn will be clearer about the difference between validating message contracts and storing events. This will make it easier for users to opt-in to the parts of the technology they need for their project.

### Positive Consequences

* Easier for users to understand the model and responsibilities
* Users can opt-in to only pieces they need

### Negative Consequences

* Have to rework protocol docs, library names, conventions, depolyment scripts, etc

## Validation

Events and messages are handled by separate libraries and the language about them is clear to users

## Pros and Cons of the Options

### Keep conflating concepts

* Pro, don't have to rewrite stuff
* Con, Much more confusing
