defmodule Polyn.Migration.Exception do
  @moduledoc """
  Exception when changing the configuration of streams and consumers
  """
  defexception [:message]
end
