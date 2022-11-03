defmodule Polyn.Messages.CloudEvent do
  # Functions for working with cloud event schema
  @moduledoc false

  @data_schema_path ["definitions", "datadef"]

  @doc """
  Read in the cloud event schema
  """
  def get_schema do
    Application.app_dir(:polyn_messages, "priv/cloud-event-schema.json")
    |> File.read!()
    |> Jason.decode!()
  end

  @doc """
  Mix a message schema with a cloud event schema so that there's only one
  unified schema to validate against
  """
  def merge_schema(cloud_event_schema, schema) do
    put_in(cloud_event_schema, @data_schema_path, schema)
  end

  @doc """
  Lookup the part of the cloud event schema specific to the data
  """
  def data_schema(cloud_event_schema) do
    get_in(cloud_event_schema, @data_schema_path)
  end
end
