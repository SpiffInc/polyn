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
    stream = struct(Stream, opts)
    Stream.update(Connection.name(), stream) |> IO.inspect(label: "UPDATE")
  end

  def execute({_id, command}) do
    execute(command)
  end

  def execute(command) do
    raise Polyn.Migration.Exception,
          "Command #{inspect(command)} not recognized"
  end
end
