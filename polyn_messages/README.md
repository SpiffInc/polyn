# Polyn Messages

Elixir library for the central management of Polyn message schemas.

## Configuration

### NATS connection

Polyn Messages usese [NATS](https://nats.io/) for passing messages. As such you need to configure your [connection settings](https://hexdocs.pm/gnat/Gnat.ConnectionSupervisor.html#content) to your NATS server(s).

```elixir
import Config

config :polyn_messages, :nats_connection_settings, [
  %{host: "127.0.0.1", port: 4222}
]
```

## Usage

To update your NATS server with message schema changes, stream changes, and consumer changes run `mix polyn.migrate`

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

