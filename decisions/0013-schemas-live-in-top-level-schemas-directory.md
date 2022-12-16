---
status: accepted
date: 2022-12-18
deciders: Brandyn Bennett, Kobi Eshun
consulted:
informed:
---
# Schemas Live in Top Level Schemas Directory

## Context and Problem Statement

There are multiple kinds of message schemas we need to use, not just events.

## Decision Drivers

* Clearer naming

## Considered Options

* Different top level folder for other schemas
* Change top level name

## Decision Outcome

Change top level name to `schemas`.

### Positive Consequences

* `schemas` is a more affordant name than `events`

### Negative Consequences

* Have to update existing uses

## Validation

`Polyn Events` codebases will have a `schemas` top level dir instead of a `events` one. Polyn-cli will find all schemas inside the `schemas` dir

## Pros and Cons of the Options

### Different top level folder for other schemas

Make a special top level folder for other schemas

* Pro, Clear where the other ones live
* Pro, Don't change existing project top level name
* Con, Schemas aren't all together in one folder
* Con, Teams can't keep all their schemas in one dir


