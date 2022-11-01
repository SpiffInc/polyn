defmodule Polyn.MigrationException do
  @moduledoc """
  Error raised when schema migrations fail
  """
  defexception [:message]
end
