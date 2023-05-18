defmodule Polyn.JSONStoreException do
  @moduledoc """
  Error raised when there are problems with accessing a key value store
  """
  defexception [:message]
end
