{ pkgs, ... }:
{
  home.packages = [
    pkgs.ty
    pkgs.ruff
    # On macOS nixpkgs' hardcode-lldb.patch makes the attach command
    # start with lldb's store path, which test_lldb_command rejects
    # because it expects a bare `lldb`. overridePythonAttrs edits the
    # arguments nixpkgs passed to buildPythonPackage.
    (pkgs.python3Packages.debugpy.overridePythonAttrs (old: {
      disabledTests = (old.disabledTests or [ ]) ++ [ "test_lldb_command" ];
    }))
  ];
}
