import Config

config :polyn_messages, :nats_connection_settings, %{
  name: :gnat,
  connection_settings: [
    %{host: "127.0.0.1", port: 4222}
  ]
}
