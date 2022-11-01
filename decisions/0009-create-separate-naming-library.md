---
status: accepted
date: 2022-11-01
deciders: Brandyn Bennett
consulted:
informed:
---
# Create separate naming library

## Context and Problem Statement

The elixir polyn_client library as well as the polyn_messages library both need the same naming validation functionality.

## Decision Drivers

* Deduplication
* Maintainability
* Dependency Management

## Considered Options

* Keep it all in polyn_elixir_client
* Separate library
* Duplicate functions on each

## Decision Outcome

Make a separate `polyn_naming` library

### Positive Consequences

* Only one single place to go think about naming rules

### Negative Consequences

* Possible for 2 polyn_naming versions to exist in a single app with conflicting rules
* Increased temptation/opportunity to make this library a "sharing" junk drawer with no clear responsibilty

## Validation

Will be simpler to maintain and manage dependencies

## Pros and Cons of the Options

### All in polyn_elixir_client

`polyn_elixir_client` would house all naming rules and other libraries that need the rules would need to depend on it direclty

* Pro, less libraries to maintain
* Con, `polyn_messages` doesn't need the vast majority of `polyn_elixir_client` functionality
* Con, `polyn_events` does need the `polyn_elixir_client` functionality and if both `polyn_messages` and `polyn_events` were in the same application you might have two `polyn_elixir_client` versions

### Duplicate functions on each

Each library that needs naming rules would copy it into its own library code

* Pro, each library is isolated, naming changes in one don't affect the other
* Con, have to update rules on both and it's easier to forget
