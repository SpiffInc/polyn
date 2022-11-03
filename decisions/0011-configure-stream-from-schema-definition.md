---
status: accepted
date: 2022-11-03
deciders: Brandyn Bennett
consulted:
informed:
---
# Configure Stream From Schema Definition

## Context and Problem Statement

We expect each message schema to be associatd with one NATS Stream. We need a way to create that stream in the conventional way.

## Decision Drivers

* Developer experience
* Consistency
* Maintainability
* Efficiency

## Considered Options

* Create a [terraform](https://developer.hashicorp.com/terraform) file
* Use the schema definition and a NATS client library

## Decision Outcome

Use the schema definition and a NATS client library.

We'll choose some defaults to create a stream from any given message schema. A `stream_config` key can be added to override some defaults if necessary

### Positive Consequences

* Less technology to manage
* Easier to do dynamic things
* Less work for the engineers
* Only have to access NATS one way

### Negative Consequences

* The stream declaration will not be as clear as with terraform
* May be confusing if a use case arises requiring a stream to hold multiple message schemas
* Will have to do change tracking ourselves

## Validation

Each message schema will have a stream created with it automatically. Deleting a schema will also delete the stream. Updating releveant fields in the schema will update the stream

## Pros and Cons of the Options

### Use Terraform

Use the Infrasture as Code, Terraform, to declare the stream configuration.

* Pro, explicit what the stream is
* Pro, can do anything you want with the stream
* Con, more tech to manage
* Con, harder to follow conventions
* Con, more for engineers to learn and do
