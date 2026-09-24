{
  lib,
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.age
  ]
  # The Secure Enclave plugin; age finds it by its `age-plugin-` name
  # and it stays inert until an `age1se1…` recipient is used.
  ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.age-plugin-se ];
}
