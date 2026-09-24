{
  description = "Empty stand-in for the private work layer";

  # For building nix-config without access to the work repository:
  #   --override-input work path:./stubs/work
  #
  # Both attributes the real layer exports, so a host importing either
  # one still evaluates.
  outputs = _: {
    darwinModules.default = { };
    homeModules.default = { };
  };
}
