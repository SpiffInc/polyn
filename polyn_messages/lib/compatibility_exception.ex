defmodule Polyn.CompatibilityException do
  @moduledoc """
  Error raised when schemas have breaking changes and/or compatibility issues
  """
  defexception [:message]
end
