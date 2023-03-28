defmodule Polyn.Migration.Exception do
  @moduledoc """
  Exception when changing running migrations for streams and consumers
  """
  defexception [:message]
end
