# Polyn Protocol (v 0.1.0)

This documentation describes how Polyn compliant clients should be implemented.

## Conformance

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT",
"RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in
[RFC2119](https://datatracker.ietf.org/doc/html/rfc2119).

## Definitions

- **application** - a single process that implements one or more components.
- **event** - any message being published to the transporter by the clients.
- **message bus** - the NATS JetStream message bus
- **components** - an event consumer that implements one or more event endpoints
- **subscriptions** - any endpoint within a service that implements specific business logic to be triggered as the result of consuming a subscribed event.
- **type** - a reverse domain name representing a unique event.
- **uuid** - a [UUID v4](https://datatracker.ietf.org/doc/html/rfc4122) compliant UUID.
- **Schema Repository** - a NATS KeyValue backed store of all events published by registered Polyn
  components.

## Message Format

A Polyn client MUST publish events that comply with the
[CloudEvents JSON](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/formats/json-format.md)
specification. In addition a client MUST add a `polyndata` extension as described
[here](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/formats/json-format.md#2-attributes).

While CloudEvents supports multiple formats, for simplicities sake, Polyn clients only support the JSON version of the spec.

### Example

```json
{
  "specversion" : "1.0.1",
  "type" : "<type>",
  "source" : "location or name of service",
  "id" :  "<uuid>",
  "time" : "2018-04-05T17:31:00Z",
  "polyndata": {
    "clientlang": "ruby",
    "clientlangversion": "3.2.1",
    "clientversion": "0.1.0"
  },
  "datacontenttype" : "application/json",
  "data" : {}
}
```

### CloudEvents Extensions

Polyn Clients MUST implement the following extensions.

#### `polyndata`

This is an object representing the information about the client that published the event as well as additional metadata. A Polyn client SHOULD NOT however fail to consume the event if the `polyndata` extension is missing.

##### Example

```json
{
  "clientlang": "ruby",
  "clientlangversion": "3.2.1",
  "clientversion": "0.1.0"
}
```

### Additional Field Requirements

#### `datacontenttype`

A Polyn client SHOULD add the `datacontenttype` field as defined [here](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md#datacontenttype)
before publishing events that correctly match the content type of the `data` field. It MUST at a minimum be able to serialize and deserialize the `application/json` content type.

If the `datacontenttype` is not present in the event, a Polyn client MUST assume that the content type is `application/json`. If the data cannot be deserialized, the client MUST broadcast an [appropriate error]().

#### `data`

A Polyn client MUST add its message data to the `data` attribute of the CloudEvent. The data format must match the `datacontentype` field.

## Message Schema

Each message MUST be associated with a JSON Schema.

### Polyn Specific Fields

The following fields can be included in the root of the `data` section of a message's JSON Schema (not the root of the CloudEvent schema).

#### `identity`

An `identity` field SHOULD be included for messages that are about a specific [domain entity](https://blog.jannikwempe.com/domain-driven-design-entities-value-objects#heading-entities). The value of the `identity` field MUST be the same as one of the [properties](https://json-schema.org/understanding-json-schema/reference/object.html#properties) defined on an `object` type schema.

#### `stream_config`

A `stream_config` field can be included to overrwrite the defaults for the NATS stream associated with the message schema. Its value MUST be an `object`.

## Message Validation

A Polyn client MUST support loading a [JSON Schema](https://json-schema.org/) document for each message. The Schema Repository SHOULD be a JetStream KeyValue Bucket called `POLYN_SCHEMAS`. A Polyn client MUST validate that the entire message is a valid CloudEvent schema. It should also validate that the `data` property of the message conforms to a JSON Schema loaded from the KeyValue bucket.

If the Schema Respository bucket does not exist Polyn MUST raise an exception that says:

```
The Schema Store has not been setup on your NATS server. Make sure you use the Polyn CLI to create it"
```

If there's no schema for the event `type`, Polyn MUST raise an exception that says:

```
Schema for #{type} does not exist. Make sure it's been added to your `schemas` codebase and has been loaded into the schema store on your NATS server
```

If a received message can't be parsed as JSON, Polyn MUST raise an exception that says:

```
"Polyn was unable to decode the following message: \n{message}"
```

If a received message is not valid and a Consumer is being used to access it, Polyn MUST send an `ACKTERM` to the Consumer so that the message won't be resent

### Schema Backwards Compatibility

A Polyn client SHOULD check the Schema Repository for event schema of the same name before
publishing its events to the repository. It SHOULD validate that the event schema to be published
are backwards compatible with the schema

Changes considered to break backwards compatibility are considered to be:

- removing or renaming fields, including deep changes within objects
- changing field data types

Adding fields SHOULD be considered to be a backwards compatible change.

### Validation on Publish

A valid Polyn client SHOULD validate events against their respective JSON schema before publishing
the event to the bus.

### Validation on Receive

A valid Polyn client SHOULD validate events received against their respective JSON schema before
processing said events.

## NATS JetStream

### Publishing

A Polyn client MUST publish full CloudEvent messages utilizing [NATS Jetstream](https://docs.nats.io/nats-concepts/jetstream). The subject should be the type of the event. For example if the event type were
`app.widgets.created.v1` the client MUST publish the event to the `app.widgets.created.v1` subject.

Each message published should include a [`"Nats-Msg-Id"`](https://docs.nats.io/using-nats/developer/develop_jetstream/model_deep_dive#message-deduplication) header to prevent duplicate messages being published.
The value of the header should be the same id as the CloudEvent id

#### Identity

If a message schema has an `identity` key. The Polyn client MUST use the `identity` value as the last token of the subject. For example given a `user.created.v1` schema with `{"identity": "id"}` inside and a payload of `{"id": "abc123"}` the published subject would be `user.created.v1.abc123`

### Subscribing

A Polyn client MUST subscribe its components to a [NATS JetStream consumer](https://docs.nats.io/nats-concepts/jetstream/consumers)
whose name is component name and event type delimited by underscores (`_`).

For example, if the application reverse domain were `app.widgets`, and the component consuming events
were the `new_widget_notifier` component, and that component was subscribing to `app.widgets.created.v1`,
the `new_widget_notifier_app_widgets_created_v1`.

A Polyn client MUST NOT attempt to set up its own consumers. This is handled by the [Polyn CLI](https://github.com/SpiffInc/polyn/tree/main/polyn_cli) within the generated `schemas` repository

If a consumer does not exist when attempting to subscribe Polyn MUST raise an exception that says

```
Consumer {name} does not exist. Use polyn-cli to create it before attempting to subscribe
```

### Streams

Each message schema MUST have exactly one [Stream](https://docs.nats.io/nats-concepts/jetstream/streams) associated with it. The `subjects` of the stream MUST have one item.

#### Non-identity message

If the message schema does not have an `identity` key the subject will be the name of the message (e.g. `subjects: ["widgets.created.v1"]`)

#### Identity message

If the message schema has an `identity` key the subject will be the name of the message concatanated with one token for the identity value. For example, if a message schema named `user.created.v1` had an `identity` key of `id`, the stream `subjects` would be `"user.created.v1.*"`.

## JetStream Migrations

Polyn clients MUST implement a migration system for JetStream configuration. Each change to the JetStream configuration should have a new file with a name that looks like this:
```
<timestamp>_<name_of_migration>.<extension>
```

For example: `20230519173058_create_user_stream.exs`

The timestamp MUST be an integer timestamp that can be used as the id to uniquely identify the migration. The timestamps must be the same number of characters so they can be sorted.

Migrations that are run must be included in a Key Value bucket named `POLYN_MIGRATIONS`. Each application should have its own key which is the `source_root` for that application. The value should be a sorted JSON array of integer timestamps of the migration files that have already run successfully.