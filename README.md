# Polyn

Polyn is a message validation framework for the [NATS](https://nats.io/) messaging system. When publishing messages in NATS there are no restrictions about what the structure of the message is. This can lead to unexpected errors and make it difficult to anticipate what data to expect in a given message.

Polyn remedies this by defining [JSON Schema](https://json-schema.org/) contracts for messages that are validated by client libraries when messages are published and consumed. Knowing what fields are available and having those contracts enforced leads to a more predictable and reliable system.

## Protocol

Polyn defines a protocol, that the client libraries adhere to, to ensure consistency. The protocol is defined [here](polyn_protocol/README.md)

## Client Libraries

Polyn has the following client libraries:

* [Elixir](polyn_elixir_client/README.md)
* [Ruby](polyn_ruby_client/README.md)

