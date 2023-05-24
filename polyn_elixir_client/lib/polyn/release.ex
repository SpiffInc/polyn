defmodule Polyn.Release do
  @moduledoc """
  Utilities for working with Polyn and mix releases.
  `mix` and mix tasks aren't available in a release. This module
  provides a way to run migrations in a release.
  """

  alias Polyn.Migration

  # Using a compile-time env to avoid the chicken-egg problem
  # of needing the application to be loaded to get the env
  # to load the application
  @otp_app Application.compile_env!(:polyn, :otp_app)

  @doc """
  Run migrations in a release

  ## Examples

      ```
      mix release
      _build/prod/rel/my_app/bin/my_app eval "Polyn.Release.migrate"
      ```
  """
  def migrate do
    load_app()

    Migration.Migrator.run()
  end

  defp load_app do
    Application.load(@otp_app)
    {:ok, _apps} = Application.ensure_all_started(:polyn)
  end
end
