---
status: accepted
date: 2022-10-28
deciders: Brandyn Bennett
consulted:
informed:
---
# Name Generated Codebase "Polyn Hive"

## Context and Problem Statement

There needs to be a centralized service that can manage message schemas as well as an event store. For a new project `polyn_new` can generate the boilerplate for this service. It needs a name though.

## Decision Drivers

* Affordance
* Clarity
* Metaphors

## Considered Options

* polyn_admin - Sounds too much like a live dashboard to monitor metrics or something
* polyn_central - It is central, but there could be multiple of these existing if each Bounded Context wanted one. Sounds too much like train metaphors which is unrelated to bees and pollen
* polyn_config
* polyn_coordinator
* polyn_store - It's not just a store, can be used without an event store
* polyn_manager - You do manage your stuff here, but doesn't quite fit
* polyn_hive
* polyn_command_center - Does deal with commands, but more happens than just commands

## Decision Outcome

Polyn Hive.

The metaphor of a Hive does match pretty well with what the codebase does. Bees go back and forth to a Hive kind of likes messages go back and forth between services.

### Positive Consequences

* It does represent a central place
* It's a fun metaphor that fits with "pollen"

### Negative Consequences

* Someone might not get the metaphor (too cute?)

## Validation

Generated codebases will be called `polyn_hive` by default (overrideable). Users will understand the metaphor.
