defmodule Mix.Tasks.Polyn.Gen.ReleaseTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Polyn.Gen

  @moduletag :tmp_dir

  # send output to test process rather than stdio
  Mix.shell(Mix.Shell.Process)

  test "makes release file", %{tmp_dir: tmp_dir} do
    Gen.Release.run(["--dir", tmp_dir])

    path = Path.join(tmp_dir, "polyn_release.ex")
    file = File.read!(path)

    assert File.exists?(path)
    assert file =~ "Polyn.Polyn.Release"
    assert file =~ "@app :polyn"
    assert [{Polyn.Polyn.Release, _binary}] = Code.compile_string(file)
  end
end
