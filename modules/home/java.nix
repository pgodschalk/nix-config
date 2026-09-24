{
  config,
  pkgs,
  substituteFile,
  ...
}:
let
  # jdtls is an Eclipse application, and Equinox needs a writable
  # configuration area. Ours is in the store and read-only, so without
  # this Equinox falls back to `~/.eclipse/<id>/configuration`. Cache
  # rather than data: it is regenerable bundle state.
  jdtlsConfigArea = "${config.xdg.cacheHome}/jdtls/configuration";

  # modules/home/darwin/zed.nix carries the same pin for jdtls'
  # `java_home`; move both together.
  # @VERSION https://openjdk.org/projects/jdk/
  jdk = pkgs.jdk25;

  # jdtls.py picks its interpreter from JAVA_HOME and falls back to
  # whatever `java` is on PATH, neither of which is reliable for a
  # Dock-launched editor. `--set-default` still lets a project that
  # exports its own JAVA_HOME win, and this chooses only the JVM the
  # server runs on, not what a project compiles against.
  jdtls = pkgs.symlinkJoin {
    name = "jdtls-${pkgs.jdt-language-server.version}";
    paths = [ pkgs.jdt-language-server ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = substituteFile ./java/wrap-jdtls.sh {
      jdk = "${jdk}";
      configArea = jdtlsConfigArea;
    };
  };
in
{
  home.packages = [
    # A floor, since jdtls cannot run without a JDK; a repo pinning a
    # version through mise still wins.
    jdk

    jdtls
  ];

  # The two Eclipse settings files jdtls reads are a store path rather
  # than a file under the data directory, because jdtls reads them as
  # URLs and XDG_DATA_HOME here contains a space. See
  # pkgs/jdtls-settings.nix.
}
