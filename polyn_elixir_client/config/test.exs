import Config

config :polyn, :domain, "com.test"
config :polyn, :source_root, "user.backend"

config :polyn, :nats, %{
  name: :gnat,
  connection_settings: [
    %{host: "localhost", port: 4222}
  ]
}

# Collect trace data for tests
# https://opentelemetry.io/docs/instrumentation/erlang/testing/
config :opentelemetry, traces_exporter: :none

config :opentelemetry, :processors, [
  {:otel_simple_processor, %{}}
]
