---
status: accepted
date: 2022-11-03
deciders: Brandyn Bennett
consulted:
informed:
---
# Disallow Deleting Schemas

## Context and Problem Statement

In previous Polyn versions you could delete a schema and as part of the migration task the schema would be removed from the Key Value store. There are times when a schema/message/stream is no longer useful and should be cleaned up

## Decision Drivers

* Developer experience
* Maintainability
* Storage costs
* Reliability

## Considered Options

* Provide no mechanism for deletion
* Delete automatically if schema is removed
* Provide out-of-band task for deletion

## Decision Outcome

Provide out-of-band task for deletion. Will make a mix task that can cleanup a schema from NATS.

### Positive Consequences

* Gives a clear path for deleting unused schemas when it is certain they are no longer useful.
* Enables compatibility warnings at migration time to enforce safe practices
* System will be more reliable as more intention will be needed to make a breaking change

### Negative Consequences

*

## Validation

Schemas won't be deleted as part of migration tasks, and warnings will happen if schemas are removed.

## Pros and Cons of the Options

### Provide no mechanism for deletion

Don't give any tools to delete schemas and assume no deleting will happen

* Pro, Breaking changes from schema deletion won't happen
* Con, Stale thing will likely sit around forever and hurt server cost and engineering productivity

### Delete automatically if schema is removed

If a schema file is deleted it will automatically delete the corresponding NATS resources

* Pro, It's easy to clean things up
* Con, It's too easy to clean things up and breaking changes could happen more often
