defmodule Mix.Tasks.Polyn.Delete.Schema do
  @moduledoc """
  Deletes a [JSON Schema](https://json-schema.org/) and associated NATS resources for a message.
  This is meant to be used outside of normal workflows to delete a schema ad-hoc when engineers are
  certain that it is no longer being used. This task will delete the schema file, the entry in the
  Polyn Schema Registry, and the associated NATS Stream. This is a breaking change to your system
  and should be done with caution.

  ```bash
  mix polyn.delete.schema NAME
  ```

  ## Subdirectories

  You can delete a schema in subdirectory by specifying the path `mix polyn.delete.schema some/nested/dir/widgets.created.v1`
  """
  @shortdoc "Delete a message schema"

  use Mix.Task
  alias Jetstream.API.KV

  defstruct [:base_dir, :message_name, :message_dir, :store_name]

  @conn_name :delete_schema_gnat

  @impl Mix.Task
  def run(args) do
    {opts, [message_path]} =
      OptionParser.parse!(args, strict: [dir: :string, store_name: :string])

    args =
      struct!(__MODULE__,
        base_dir: Keyword.get(opts, :dir, File.cwd!()),
        message_name: Path.basename(message_path),
        message_dir: Path.dirname(message_path),
        store_name: get_store_name(opts)
      )

    start_nats_connection()

    unless Mix.env() == :test do
      Mix.shell().yes?(
        "You are about to delete a message schema. This is a breaking change." <>
          "Are you sure that there are no services in your system that are depending on this schema" <>
          "and its messages?",
        default: :no
      )
    end

    relative_path = Path.join(args.message_dir, "#{args.message_name}.json")
    Mix.shell().info("Deleting schema file #{relative_path}")

    Path.join([args.base_dir, "message_schemas", relative_path])
    |> File.rm!()

    Mix.shell().info("Deleting schema key #{args.message_name} from schema store")
    KV.delete_key(@conn_name, args.store_name, args.message_name)
  end

  defp get_store_name(opts) do
    opts[:store_name] || Polyn.Messages.default_schema_store()
  end

  defp start_nats_connection do
    connection_settings = Application.get_env(:polyn_messages, :nats_connection_settings)

    # Not using the `Gnat.ConnectionSupervisor` because this is not a long-lived process
    Gnat.start_link(Enum.random(connection_settings), name: @conn_name)
  end
end
