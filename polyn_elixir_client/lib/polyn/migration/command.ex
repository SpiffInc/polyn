defmodule Polyn.Migration.Command do
  # Where we execute the commands
  @moduledoc false

  alias Jetstream.API.Stream
  alias Polyn.Connection

  @doc "Actually apply the change to the server"
  def execute({:create_stream, opts}) do
    stream = struct(Stream, opts)

    case Stream.create(Connection.name(), stream) do
      {:error, reason} -> raise Polyn.Migration.Exception, inspect(reason)
      success -> success
    end
  end

  def execute({:update_stream, opts}) do
    stream = update_stream_config(opts)

    case Stream.update(Connection.name(), stream) do
      {:error, reason} -> raise Polyn.Migration.Exception, inspect(reason)
      success -> success
    end
  end

  def execute({_id, command}) do
    execute(command)
  end

  def execute(command) do
    raise Polyn.Migration.Exception,
          "Command #{inspect(command)} not recognized"
  end

  # We only want to require that changed attributes are passed in the migration.
  # The %Stream{} struct requires certain fields that may already be set. We want
  # to get those from the existing config
  defp update_stream_config(opts) do
    info =
      case Stream.info(Connection.name(), opts[:name]) do
        {:ok, info} -> info
        {:error, reason} -> raise Polyn.Migration.Exception, inspect(reason)
      end

    Map.merge(info.config, Map.new(opts))
  end
end
