defmodule Mix.Tasks.Polyn.Gen.SchemaTest do
  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  test "generates a message schema", %{tmp_dir: tmp_dir} do
    Mix.Task.rerun("polyn.gen.schema", ["widgets.created.v1", "--dir", tmp_dir])

    contents =
      File.read!(Path.join(tmp_dir, "message_schemas/widgets.created.v1.json"))
      |> Jason.decode!()

    assert contents["$id"] == "widgets:created:v1"
  end

  test "generates a nested message schema", %{tmp_dir: tmp_dir} do
    Mix.Task.rerun("polyn.gen.schema", ["foo/bar/widgets.created.v1", "--dir", tmp_dir])

    contents =
      File.read!(Path.join(tmp_dir, "message_schemas/foo/bar/widgets.created.v1.json"))
      |> Jason.decode!()

    assert contents["$id"] == "widgets:created:v1"
  end

  test "error if invalid message name", %{tmp_dir: tmp_dir} do
    assert_raise(Polyn.NamingException, fn ->
      Mix.Task.rerun("polyn.gen.schema", ["widgets_created_v1", "--dir", tmp_dir])
    end)
  end
end
