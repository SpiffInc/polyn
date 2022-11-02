# General application configuration
import Config

config :polyn_hive, PolynHive.CommandedApplication,
  # https://hexdocs.pm/commanded_extreme_adapter/getting-started.html#content
  event_store: [
    adapter: Commanded.EventStore.Adapters.Extreme,
    serializer: Commanded.Serialization.JsonSerializer,
    stream_prefix: "polyn_events",
    extreme: [
      db_type: :node,
      host: "localhost",
      port: 1113,
      username: "admin",
      password: "changeit",
      reconnect_delay: 2_000,
      max_attempts: :infinity
    ]
  ],
  pubsub: :local,
  registry: :local,
  snapshotting: %{}

config :polyn_messages, :nats_connection_settings, %{
  name: :gnat,
  connection_settings: [
    %{host: "127.0.0.1", port: 4222}
  ]
}
