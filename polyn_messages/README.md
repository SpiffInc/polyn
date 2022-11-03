# Polyn Messages

Elixir library for the central management of Polyn message schemas.

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

### Migrate Schemas

To update your NATS server with message schema changes, stream changes, and consumer changes run `mix polyn.migrate`

### Delete Schema

A mix task is available to delete a schema and its associated resources on your NATS server. This is meant to be used ad-hoc when a schema can safely be removed from this system. This is a *breaking change* and should be done with caution when you are sure that no system resources are depending on the schema.

```elixir
mix polyn.delete.schema widgets.created.v1
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `polyn_messages` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:polyn_messages, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/polyn_messages>.

