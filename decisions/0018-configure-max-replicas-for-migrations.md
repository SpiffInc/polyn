---
status: accepted
date: 2023-05-25
deciders: Brandyn Bennett
consulted:
informed:
---
# Configure max replicas for migrations

## Context and Problem Statement

How do we handle the number of stream replicas for migrations in different environments?
It's likley that dev and test environments will only have one nats-server running whereas
production will have a cluster. How do we ensure migrations can be run in both environments
without breaking?

## Decision Drivers

* Reliability
* Ease-of-use
* Consistency

## Considered Options

* Dynamically determine from running server info
* Explicit app config

## Decision Outcome

Explicit App Config

Engineers will specify the max replicas in an environment config file

### Positive Consequences

* It will be clear what the limit is
* Less error prone

### Negative Consequences

* One more thing to configure
* Won't be automatic

## Pros and Cons of the Options

### Dynamically Determine

We could maybe use the [connect_urls](https://docs.nats.io/reference/reference-protocols/nats-protocol#connect_urls)
field to auto-infer what the max replicas should be

* Pro, no extra config for engineers
* Con, error prone. If a prod migration happens while a server is down the wrong
number of replicas may get applied. Using the urls in the application config is also
not reliable as a proxy, cluster url could look like one url, but represent many.
* Con, optional field. `connect_urls` is considered optional and we may not
be able to rely on it
* Con, more complex
