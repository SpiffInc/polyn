---
status: accepted
date: 2022-12-20
deciders: Brandyn Bennett, Jarod Reid
consulted:
informed:
---
# Store Full Cloud Event Schema in KV Store

## Context and Problem Statement

The Polyn clients will get schemas out of a NATS Key-Value store to validate a message. Messages are expected to be part of the cloudevent spec, but the schema file for the payload doesn't contain the whole cloudevent spec.

It was decided a few months back outside of the ADR system to store the combined schema in the key value store. This ADR is revisiting that decision in light of the desire to include and resolve non-message schemas in the KV store.

## Decision Drivers

* Maintainance
* Ergonomics
* Performance
* Versioning

## Considered Options

* KV store contains combined cloudevent schema and payload schema
* KV store contains only payload schema

## Decision Outcome

KV store contains only payload schema.

The KV store wouldn't know about the cloudevent schema and would only store the payload schema. Would need to do a cloudevent validation and a payload validation which is happening anyway.

### Positive Consequences

* The KV store would have same schemas as the schema files
* Resolution paths would be simple and just focus on payload schemas
* The cloud event schema wouldn't be duplicated all throughout the KV store
* The cloudevent schema already has a `specversion` property so clients would know which version to check against.

### Negative Consequences

## Validation

KV store only has payload schemas and client tools do cloudevent validation separate from payload validation.

## Pros and Cons of the Options

### KV store contains combined cloudevent schema.

The CLI tool handles the combining when uploading.

* Pro, The cloudevent schema version will be a part of the full Schema
* Pro, There won't be two schema versions to worry about at runtime, the cloudevent version and the payload version.
* Con, Not all schemas are full cloudevent message schemas (shared schema snippets). Resolution paths in the files wouldn't match the end state.
* Con, If the cloudevent schema has a breaking change all the payload schemas would have to cut a new version. The CLI tool would have to persist payload schemas with old cloudevent version and with new version. It would be confusing to the developer why there were two identical payload schemas with different version numbers. The payload schema would have to know which cloudevent version it belonged to, which it probably should anyway.

