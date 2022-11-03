# PolynHive

Elixir application for the central management of Polyn.

## Naming Conventions

See the Protocol Documentation for [Naming Conventions](https://github.com/SpiffInc/polyn/blob/main/polyn_protocol/NAMING_CONVENTIONS.md)

## Schema Versioning

### New Schema

A new schema file should be a lower-case, dot-separated, name with a `v1` suffix

### Existing Schema

Existing schemas can be changed without updating the file name if the change is backwards-compatible. Backwards-compatibile meaning that any services Producing or Consuming the event will not break or be invalid when the Polyn Schema Registry is updated with the change. There are many ways to make breaking change and so you should be careful when you do this.

Making a change to an schema that is not backwards-compatible will require you to create a brand new json file. The new file should have the same name as your old file, but with the version number increased. Your Producers will need to continue producing both events until you are sure there are no more consumers using the old event.

## Configuration

### NATS connection

Polyn Messages uses [NATS](https://nats.io/) for passing messages. As such you need to configure your [connection settings](https://hexdocs.pm/gnat/Gnat.ConnectionSupervisor.html#content) to your NATS server(s).

```elixir
import Config

config :polyn_messages, :nats_connection_settings, [
  %{host: "127.0.0.1", port: 4222}
]
```

## Usage

### Generate a Schema

Run `mix polyn.gen.schema MESSAGE_NAME` to generate a new JSON Schema for a message

All the schemas for your messages should live in the `./message_schemas` directory.
The name of your schema file should be the same as your message name, but with `.json` at the end.
So if you have a message called `widgets.created.v1` you would create a schema file called `widgets.created.v1.json` in the `./message_schemas` directory. Every schema should be a valid [JSON Schema](https://json-schema.org/) document.
The mix task will combine your message schema with the [Cloud Events Schema](https://cloudevents.io/) when it adds it to the Polyn Schema Registry. This means you only need to include the JSON Schema for the `data` portion of the Cloud Event and not the entire Cloud Event schema.

#### Subdirectories

If you'd like to organize your message schemas by team ownership or some other convention, you can use subdirectories to do so.
The full message type should still be part of the file name. You should also ensure there are not duplicate message names in
different directories as only one schema can be defined per message type.

You can generate a schema in a subdirectory like this: `mix polyn.gen.schema some/nested/dir/widgets.created.v1`

### Migrate Schemas

To update your NATS server with message schema changes, stream changes, and consumer changes run `mix polyn.migrate`

### Delete Schema

A mix task is available to delete a schema and its associated resources on your NATS server. This is meant to be used ad-hoc when a schema can safely be removed from this system. This is a *breaking change* and should be done with caution when you are sure that no system resources are depending on the schema.

```elixir
mix polyn.delete.schema widgets.created.v1
```

#### Subdirectories

You can delete a schema in subdirectory by specifying the path `mix polyn.delete.schema some/nested/dir/widgets.created.v1`


