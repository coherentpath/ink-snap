defmodule Mix.Tasks.InkSnap.CheckTest do
  use ExUnit.Case, async: false

  @orphan "test/_snapshots/ink_snap_test/test_orphan_snapshot_from_test.snap"

  setup do
    on_exit(fn -> File.rm(@orphan) end)
    :ok
  end

  describe "mix ink_snap.check" do
    test "passes and exits 0 when there are no unused snapshots" do
      {out, status} = run([])

      assert status == 0
      assert out =~ "No unused snapshots found."
    end

    test "reports orphans and exits 1" do
      File.write!(@orphan, "%{}\n")

      {out, status} = run([])

      assert status == 1
      assert out =~ "Found 1 unused snapshot(s)"
      assert out =~ "test_orphan_snapshot_from_test.snap"
      assert File.exists?(@orphan), "should not delete without --clean"
    end

    test "--clean deletes orphans and exits 0" do
      File.write!(@orphan, "%{}\n")

      {out, status} = run(["--clean"])

      assert status == 0
      assert out =~ "Removed 1 unused snapshot(s)"
      refute File.exists?(@orphan)
    end

    test "--clean prunes directories left empty" do
      dir = "test/_snapshots/nonexistent_test"
      snap = Path.join(dir, "test_gone.snap")
      File.mkdir_p!(dir)
      File.write!(snap, "%{}\n")
      on_exit(fn -> File.rm_rf(dir) end)

      {_out, status} = run(["--clean"])

      assert status == 0
      refute File.exists?(snap)
      refute File.dir?(dir), "empty snapshot dir should be pruned"
    end
  end

  # Run the task in an isolated subprocess (test env, so no re-exec) to avoid
  # recursively compiling/starting ExUnit inside the running suite.
  defp run(args) do
    System.cmd("mix", ["ink_snap.check" | args],
      env: [{"MIX_ENV", "test"}],
      stderr_to_stdout: true
    )
  end
end
