# Polyn Naming

Utility functions for sharing naming functionality amongst Polyn Elixir libraries

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `polyn_naming` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:polyn_naming, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/polyn_naming>.

## Configuration

### Domain

The [Cloud Event Spec](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md#type) specifies that every event "SHOULD be prefixed with a reverse-DNS name." This name should be consistent throughout your organization. You
define that domain like this:

```elixir
config :polyn, :domain, "app.spiff"
```

### Event Source Root

The [Cloud Event Spec](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md#source-1) specifies that every event MUST have a `source` attribute and recommends it be an absolute [URI](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier). Your application must configure the `source_root` to use for events produced at the application level. Each event producer can include its own `source` to append to the `source_root` if it makes sense.

```elixir
config :polyn, :source_root, "orders.payments"
```

