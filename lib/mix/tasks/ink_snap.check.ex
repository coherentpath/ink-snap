defmodule Mix.Tasks.InkSnap.Check do
  @shortdoc "Detects unused (stale) snapshot files"

  @moduledoc """
  Detects stale/orphaned snapshot files left behind when a test is renamed or
  removed after its snapshot was created.

  It works by compiling the project's test files (a dry run: modules are
  compiled but tests are **not** executed), asking ExUnit for every registered
  test, and computing the snapshot path each test would use. Any `.snap` file on
  disk that no test claims is reported as orphaned.

  ## Usage

      mix ink_snap.check

  Prints each orphaned snapshot and exits with a non-zero status when any are
  found (suitable for CI).

      mix ink_snap.check --delete

  Deletes orphaned snapshots, prunes any snapshot directories left empty, and
  exits successfully.
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    # Snapshots only exist under the test environment (that is where test files
    # and their support modules compile). Mix locks the environment before a task
    # loads and a third-party task cannot set it, so when invoked in any other
    # env we re-exec ourselves as a subprocess with MIX_ENV=test.
    if Mix.env() == :test do
      check(args)
    else
      exit({:shutdown, rerun_in_test_env(args)})
    end
  end

  defp rerun_in_test_env(args) do
    {_out, status} =
      System.cmd("mix", ["ink_snap.check" | args],
        env: [{"MIX_ENV", "test"}],
        into: IO.stream(:stdio, :line),
        stderr_to_stdout: true
      )

    status
  end

  defp check(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [delete: :boolean])
    delete? = Keyword.get(opts, :delete, false)

    Mix.Task.run("compile")
    Application.ensure_all_started(:ink_snap)
    # Start ExUnit so compiling test modules can register their tests, but never
    # let them run (this is a static dry run, not a test execution).
    ExUnit.start(autorun: false)

    expected = expected_snapshots()
    existing = existing_snapshots()
    orphans = Enum.sort(existing -- expected)

    cond do
      orphans == [] ->
        Mix.shell().info("No unused snapshots found.")

      delete? ->
        Enum.each(orphans, &File.rm!/1)
        prune_empty_dirs()

        Mix.shell().info("Removed #{length(orphans)} unused snapshot(s):")
        Enum.each(orphans, &Mix.shell().info("  #{relative(&1)}"))

      true ->
        Mix.shell().error("Found #{length(orphans)} unused snapshot(s):")
        Enum.each(orphans, &Mix.shell().error("  #{relative(&1)}"))

        Mix.shell().error("""

        Remove them by running:

            mix ink_snap.check --delete
        """)

        exit({:shutdown, 1})
    end
  end

  # Compute the set of snapshot paths that live tests would produce.
  defp expected_snapshots do
    test_files()
    |> Enum.flat_map(fn file -> Code.require_file(file) || Code.compile_file(file) end)
    |> Enum.map(fn {module, _binary} -> module end)
    |> Enum.filter(&function_exported?(&1, :__ex_unit__, 0))
    |> Enum.flat_map(fn module -> module.__ex_unit__().tests end)
    |> Enum.map(fn %ExUnit.Test{name: name, tags: %{file: file}} ->
      InkSnap.snapshot_file_for(file, name)
    end)
    |> Enum.uniq()
  end

  defp existing_snapshots do
    InkSnap.snapshot_dirs()
    |> Enum.flat_map(fn dir -> Path.wildcard(Path.join(dir, "**/*.snap")) end)
    |> Enum.uniq()
  end

  defp test_files do
    Mix.Project.config()
    |> Keyword.get(:test_paths, default_test_paths())
    |> Enum.flat_map(fn path -> Path.wildcard(Path.join(path, "**/*_test.exs")) end)
    |> Enum.map(&Path.expand/1)
    |> Enum.uniq()
  end

  defp default_test_paths do
    if File.dir?("test"), do: ["test"], else: []
  end

  # Remove snapshot subdirectories that became empty after deletion, bottom-up.
  defp prune_empty_dirs do
    for root <- InkSnap.snapshot_dirs(),
        dir <- Enum.sort([root | Path.wildcard(Path.join(root, "**/"))], :desc) do
      File.rmdir(dir)
    end
  end

  defp relative(path), do: Path.relative_to_cwd(path)
end
