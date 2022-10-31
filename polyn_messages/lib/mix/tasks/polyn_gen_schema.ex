defmodule Mix.Tasks.Polyn.Gen.Schema do
  @moduledoc """
  Generates a new [JSON Schema](https://json-schema.org/) for a message

  ```bash
  mix polyn.gen.schema NAME
  ```

  All the schemas for your messages should live in the `./message_schemas directory.
  The name of your schema file should be the same as your message name, but with `.json` at the end.
  So if you have a message called `widgets.created.v1` you would create a schema file called `widgets.created.v1.json` in the `./message_schemas`
  directory. Every schema should be a valid [JSON Schema](https://json-schema.org/) document.
  The mix task will combine your message schema with the [Cloud Events Schema](https://cloudevents.io/) when it adds it to the
  Polyn Schema Registry. This means you only need to include the JSON Schema for the `data` portion of the Cloud Event and not
  the entire Cloud Event schema.

  ## Subdirectories

  If you'd like to organize your message schemas by team ownership or some other convention, you can use subdirectories to do so.
  The full message type should still be part of the file name. You should also ensure there are not duplicate message names in
  different directories as only one schema can be defined per message type.

  You can generate a schema in a subdirectory like this: `mix polyn.gen.schema some/nested/dir/widgets.created.v1`
  """
  @shortdoc "Generates a new message schema"

  use Mix.Task
  require Mix.Generator

  defstruct [:base_dir, :message_name, :message_dir]

  @impl Mix.Task
  def run(args) do
    {opts, [message_path]} = OptionParser.parse!(args, strict: [dir: :string])

    args =
      struct!(__MODULE__,
        base_dir: Keyword.get(opts, :dir, File.cwd!()),
        message_name: Path.basename(message_path),
        message_dir: Path.dirname(message_path)
      )

    Polyn.Naming.validate_message_name!(args.message_name)

    Mix.Generator.create_file(
      Path.join([args.base_dir, "message_schemas", args.message_dir, "#{args.message_name}.json"]),
      schema_template(message_name: args.message_name)
    )
  end

  Mix.Generator.embed_template(:schema, """
  {
    "$id": "<%= @message_name %>",
    "$schema": "http://json-schema.org/draft-07/schema#",
    "description": "This is why this message exists and what it does",
    "type": "object",
    "properties": {

    }
  }
  """)
end
