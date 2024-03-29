# Polyn

Polyn is a dead simple service framework designed to be language agnostic while
providing a simple, yet powerful, abstraction layer for building reactive events
based services.

## Philosophy

According to [Jonas Boner](http://jonasboner.com/), reactive Microservices require
you to:
1. Follow the principle “do one thing, and one thing well” in defining service
   boundaries
2. Isolate the services
3. Ensure services act autonomously
4. Embrace asynchronous message passing
5. Stay mobile, but addressable
6. Design for the required level of consistency

Polyn implements this pattern in a manner that can be applied to multiple programming
languages, such as Ruby, Elixir, or Python, enabling you to build services that can
communicate regardless of the language you use.

Using an event-based microservice architecture is a great way to decouple your services,
create reliability, and scalability. However, there is no standard way to format events
which creates entropy and inconsistency between services, requiring developers to
create different event handling logic for each event type they consume. Polyn
solves this problem by creating and enforcing a consistent event format on both the
producer and consumer-side so all the services in your system can focus their
effort on the data rather than the event format.

Rather than defining its own event schema, Polyn uses the [Cloud Events](https://github.com/cloudevents/spec)
specification and strictly enforces the event format. This means that you can use Polyn to build services
that can be used by other services, or natively interact with things such as GCP Cloud Functions.

For events that include `data` Polyn also leverages the [JSON Schema](http://json-schema.org/)
specification to create consistency.

## Schema Creation

In order for Polyn to process and validate message schemas you will need to use [Polyn CLI](https://github.com/SpiffInc/polyn/tree/main/polyn_cli) to create an `schemas` codebase. Once your `schemas` codebase is created you can create and manage your schemas there.

## Configuration

### Domain

The [Cloud Event Spec](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md#type) specifies that every event "SHOULD be prefixed with a reverse-DNS name." This name should be consistent throughout your organization. You
define that domain like this:

```elixir
config :polyn, :domain, "com.my_app"
```

### Message Source Root

The [Cloud Event Spec](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md#source-1) specifies that every event MUST have a `source` attribute and recommends it be an absolute [URI](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier). Your application must configure the `source_root` to use for messages produced at the application level. Each message producer can include its own `source` to append to the `source_root` if it makes sense.

```elixir
config :polyn, :source_root, "orders.payments"
```

### NATS Connection

You will need to provide the connection settings for your NATS connection. This will differ in-between environments. More settings options can be seen [here](https://hexdocs.pm/gnat/Gnat.ConnectionSupervisor.html#content)

```elixir
config :polyn, :nats, %{
  name: :gnat,
  connection_settings: [
    %{host: "10.0.0.100", port: 4222},
    %{host: "10.0.0.101", port: 4222},
  ]
}
```

### Max Replicas

When creating/updating streams in migrations you will want to specify how
many replicas a stream should have. This can differ between environments.
Your dev/test environments may only have one server running and so the
num_replicas would be different. You can specify environments that should
have limited replicas that differ than what you specify in your migrations

```elixir
config :polyn, :max_replicas, 1
```

## Schema Store

In order for `Polyn` to access schemas for validation you'll need a running `Polyn.SchemaStore` process. You can add one to your Supervision Tree like this:

```elixir
  children = [
    {Polyn.SchemaStore, connection_name: :connection_name_or_pid}
  ]

  opts = [strategy: :one_for_one, name: MySupervisor]
  Supervisor.start_link(children, opts)
```

## Server Migrations

To create a migration you use the mix task `mix polyn.gen.migration <name>`. If you wanted to create a new stream for user messages you could do the following:

```bash
mix polyn.gen.migration create_user_stream
```

This would add a new migration to your codebase at `priv/polyn/migrations/<timestamp>_create_user_stream.exs`. The TIMESTAMP is a unique number that identifies the migration. It is usually the timestamp of when the migration was created. The NAME must also be unique and it quickly identifies what the migration does. Inside the generated file you would see a module like this:

```elixir
defmodule Polyn.Migrations.CreateUserStream do
  import Polyn.Migration

  def change do
  end
end
```

Inside the `change` function you can use the functions available in `Polyn.Migration` to update the NATS server. You can then run `mix polyn.migrate` to apply your changes.

### Rollback

You can rollback a change using `mix polyn.rollback`. Not all `Polyn.Migration` functions can be auto rolled back
in a `change/0` function. Instead you will have to define `up/down` functions explicitly.

```elixir
defmodule Polyn.Migrations.UpdateUserStream do
  import Polyn.Migration

  def up do
  end

  def down do
  end
end
```

### Tracking Previously Run Migrations

Polyn uses a shared Key-Value bucket in NATS to avoid re-running migrations. It uses the application's `:source_root` as the key to determine which list of run migrations belong to which application.

### Releases

When using `mix release` to deploy, `mix` and Mix Tasks are not available, so you can't use `mix polyn.migrate` to do your migrations.

Instead you'll need to run `mix polyn.gen.release` which will add a `lib/my_app/release.ex` file to your app (if you already have this file it will append to it). The file will look something like this:

```elixir
defmodule MyApp.Release do
  @app :my_app

  def polyn_migrate do
    load_app()
    {:ok, _apps} = Application.ensure_all_started(:polyn)

    dir = Path.join([:code.priv_dir(@app), "polyn", "migrations"])
    Polyn.Migration.Migrator.run(migrations_dir: dir)
  end

  defp load_app do
    Application.load(@app)
  end
end
```

You can use the `polyn_migrate` function from this module to execute migrations in the compiled release like this:

```
_build/prod/rel/my_app/bin/my_app eval "MyApp.Release.polyn_migrate"
```

Sometimes multiple OTP apps are part of a single application, so Polyn doesn't assume which app to use for accessing and running migration files. This is why you need to generate the `release.ex` file yourself and pass in the OTP app you want.


## Usage

### Publishing Messages

Use `Polyn.pub/4` to publish new events to the server

### Simple Stream Consumption

If you have use case that doesn't require batching or concurrency you can use `Polyn.PullConsumer` to receive messages one at a time

### Complex Stream Consumption

If you have a complex use case requiring batching or concurrency you should use the
`OffBroadway.Polyn.Producer` to create a data pipeline for your messages.

### Vanilla NATS Subscription

If there are events you want to subscribe to that are more ephemeral or don't need
JetStream functionality you can use the `Polyn.Subscriber` module to setup a process
to subscribe and handle those events

### Request-Reply

You can use `Polyn.request/4` to a do a [psuedo-synchronous request](https://docs.nats.io/nats-concepts/core-nats/reqreply). You can subscribe to an event using a `Polyn.Subscriber` and reply using `Polyn.reply/5`. Both your request and your reply will need schema definitions and will be validated against them.

## Testing

Add the following to your `config/test.exs`

```elixir
config :polyn, :sandbox, true
```

In your `test_helper.ex` add the following:

```elixir
Polyn.Sandbox.start_link()
```

In tests that interact with Polyn add

```elixir
import Polyn.Testing

setup :setup_polyn
```

### Test Isolation

Following the test setup instructions replaces *most* `Polyn` calls to NATS with mocks. Rather than hitting a real nats-server, the mocks will create an isolated sandbox for each test to ensure that message passing in one test is not affecting any other test. This will help prevent flaky tests and race conditions. It also makes concurrent testing possible. The tests will also all share the same schema store so that schemas aren't fetched from the nats-server repeatedly.

Despite mocking some NATS functionality you will still need a running nats-server for your testing.
When the tests start it will load all your schemas. The tests themselves will also use the running server to verify
stream and consumer configuration information. This hybrid mocking approach is intended to give isolation and reliability while also ensuring correct integration.

### Nested Processes

`Polyn.Testing` associates each test process with its own NATS mock. To allow other processes that will call `Polyn` functions to use the same NATS mock as the rest of the test use the `Polyn.Sandbox.allow/2` function. If you don't have access to the `pid` or name of a process that is using `Polyn` you will need to make your file `async: false`.

## Observability

### Tracing

Polyn uses [OpenTelemetry](https://opentelemetry.io/) to create distributed traces that will connect sent and received events in different services. Your application will need the [`opentelemetry` package](https://opentelemetry.io/docs/instrumentation/erlang/getting-started/) installed to collect the trace information.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `polyn` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:polyn, "~> 0.1.0"}
  ]
end
```

### Optional Broadway Dependency

To use the `OffBroadway.Polyn.Producer` you'll also need to add a `Broadway` as a
dependency

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/polyn](https://hexdocs.pm/polyn).

