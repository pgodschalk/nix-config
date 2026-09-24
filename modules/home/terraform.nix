{ pkgs, ... }:
{
  home.packages = [
    pkgs.terraform-ls

    # Load-bearing: terraform-ls formats by shelling out to a CLI, and
    # without one it still advertises the capability and silently
    # returns no edits. BUSL-1.1, so it needs an allowUnfreePredicate
    # entry; terraform-ls itself is MPL-2.0 and needs none.
    pkgs.terraform

    pkgs.tflint
  ];
}
