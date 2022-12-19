# Polyn::Cli

Polyn CLI is a tool for managing and configuring a NATS server for organizations using the Polyn protocol

## Installation

```bash
gem install 'polyn-cli'
```

## Usage

### Create New Schemas Codebase

Run `polyn init` inside a directory to create a new `schemas` respository for managing your message schemas and NATS server configuration

### Stream Generator

Run `polyn gen:stream <stream_name>` to generate a new configuration file for a stream

### Schema Generator

Run `polyn gen:schema <schema_name>` to generate a new JSON Schema for a message

### Consumer Generator

Run `polyn gen:consumer <stream_name> <destination_name> <schema_name>` to generate new configuration for a consumer of a stream. It will be included in the same file as the stream configuration.

### Updating NATS Configuration and Schemas

Run `polyn up` to update your NATS server with the latest configuration in your `./tf` directory. It will also update your Schema Repository with the latest schemas.

## Environment Variables

* `NATS_SERVERS` - locations of your servers (defaults to localhost)
* `NATS_CREDENTIALS` - path to nats credentials file
* `NATS_CA_FILE` - Fully Qualified Path to a file containing Root CA (PEM format). Use when the server has certs signed by an unknown authority.
* `NATS_TLS` - Boolean, defaults to `false`. Should NATS connect with TLS?
* `POLYN_ENV` - type of environment (defaults to "development")

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/polyn-cli. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/polyn-cli/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Polyn::Cli project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/polyn-cli/blob/master/CODE_OF_CONDUCT.md).
