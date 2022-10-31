defmodule Polyn.Naming do
  @moduledoc """
  Utilities for working with Polyn naming conventions
  """

  @doc """
  Validate the name of a message

  ## Examples

      iex>Polyn.Naming.validate_message_name("user.created")
      :ok

      iex>Polyn.Naming.validate_message_name("user  created")
      {:error, message}
  """
  @spec validate_message_name(name :: binary()) :: :ok | {:error, binary()}
  def validate_message_name(name) do
    if String.match?(name, ~r/^[a-z0-9]+(?:\.[a-z0-9]+)*$/) do
      :ok
    else
      {:error, "Message names must be lowercase, alphanumeric and dot separated"}
    end
  end

  @doc """
  Validate the name of a message. Raises if invalid

  ## Examples

      iex>Polyn.Naming.validate_message_name!("user.created")
      :ok

      iex>Polyn.Naming.validate_message_name!("user  created")
      Polyn.ValidationException
  """
  @spec validate_message_name!(name :: binary()) :: :ok
  def validate_message_name!(type) do
    case validate_message_name(type) do
      {:error, reason} ->
        raise Polyn.NamingException, reason

      success ->
        success
    end
  end
end
