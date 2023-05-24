defmodule Mix.Tasks.Polyn.Gen.ReleaseTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Polyn.Gen

  @moduletag :tmp_dir

  # send output to test process rather than stdio
  Mix.shell(Mix.Shell.Process)

  test "makes release file", %{tmp_dir: tmp_dir} do
    Gen.Release.run(["--dir", tmp_dir])

    path = Path.join([tmp_dir, "polyn", "release.ex"])

    file = File.read!(path)

    assert [{Polyn.Release, _binary}] = Code.compile_string(file)

    assert file ==
             """
             defmodule Polyn.Release do
               @app :polyn

               def polyn_migrate do
                 load_app()
                 {:ok, _apps} = Application.ensure_all_started(:polyn)

                 dir = Path.join([:code.priv_dir(@app), "polyn", "migrations"])
                 Polyn.Migration.Migrator.run(migrations_dir: dir)
               end

               defp load_app do
                 Application.load(@app)
               end
             end
             """
  end

  test "injects polyn_migrate function if release_file exists already", %{tmp_dir: tmp_dir} do
    File.mkdir!(Path.join(tmp_dir, "polyn"))

    path = Path.join([tmp_dir, "polyn", "release.ex"])

    File.write!(path, """
    defmodule Polyn.Release do
      def do_other_stuff do
      end
    end
    """)

    send(self(), {:mix_shell_input, :yes?, true})
    Gen.Release.run(["--dir", tmp_dir])

    prompt = "#{path} already exists. Would you like to inject Polyn release functions into it?"
    assert_received {:mix_shell, :yes?, [^prompt]}

    file = File.read!(path)

    assert file ==
             """
             defmodule Polyn.Release do
               def do_other_stuff do
               end

               def polyn_migrate do
                 load_app()
                 {:ok, _apps} = Application.ensure_all_started(:polyn)

                 dir = Path.join([:code.priv_dir(@app), "polyn", "migrations"])
                 Polyn.Migration.Migrator.run(migrations_dir: dir)
               end
             end
             """
  end
end
