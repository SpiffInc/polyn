defmodule Polyn.Migrator.Stream do
  @moduledoc false

  alias Jetstream.API.Stream

  @stream_name_used_with_different_config_code 10058

  def change(conn, fields) do
    stream = struct!(Stream, fields)

    case Stream.create(conn, stream) do
      {:error, %{"err_code" => @stream_name_used_with_different_config_code}} ->
        update_stream(conn, stream)

      {:error, msg} ->
        raise Polyn.StreamMigrator.Exception, inspect(msg)

      success ->
        success
    end
  end

  defp update_stream(conn, stream) do
    case Stream.update(conn, stream) do
      {:error, msg} ->
        raise Polyn.StreamMigrator.Exception, inspect(msg)

      success ->
        success
    end
  end
end
