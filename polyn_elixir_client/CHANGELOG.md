# Changelog

## 0.6.4

* Change from `uuid` lib to `elixir_uuid` lib.

## 0.6.3

* Adds `mix polyn.rollback` mix task
* Adds `up/down` functions for Polyn migrations

## 0.6.2

* Adds `:max_replicas` config option to allow for replica numbers to differ
between environments

## 0.6.1

* Adds `mix polyn.gen.release` task for working with `mix release`.

## 0.6.0

* Adds JetStream migration tooling with `mix polyn.migrate`
