defmodule Polyn.Migration.Command do
  # Where we execute the commands
  @moduledoc false

  alias Jetstream.API.Stream
  alias Polyn.Connection

  @doc "Actually apply the change to the server"
  def execute({:create_stream, opts}) do
    stream = struct(Stream, opts)
    Stream.create(Connection.name(), stream)
  end

  def execute({_id, command}) do
    execute(command)
  end

  def execute(command) do
    raise Polyn.Migration.Exception,
          "Command #{inspect(command)} not recognized"
  end
end
