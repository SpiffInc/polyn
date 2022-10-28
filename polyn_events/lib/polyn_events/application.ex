defmodule PolynEvents.Application do
  use Commanded.Application,
    otp_app: :polyn_events,
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
    snapshotting: %{
      BankAccount => [
        snapshot_every: 2,
        snapshot_version: 1
      ],
      User => [
        snapshot_every: 10,
        snapshot_version: 1
      ]
    }

  router(BankRouter)
  router(UserRouter)
end
