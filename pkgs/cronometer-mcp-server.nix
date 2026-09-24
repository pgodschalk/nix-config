{
  lib,
  python3Packages,
  fetchPypi,
  replaceVars,
  writeShellScriptBin,
}:
let
  # Community-maintained, an exception to the first-party-only rule for
  # MCP servers: Cronometer publishes no MCP server and no public API.
  # It drives the web app's GWT-RPC calls, so it needs a Cronometer Gold
  # account, and a change to the web app can break it without warning.
  server = python3Packages.buildPythonApplication rec {
    pname = "cronometer-mcp";
    # @VERSION https://github.com/cphoskins/cronometer-mcp/releases
    version = "2.2.0";
    pyproject = true;

    src = fetchPypi {
      pname = "cronometer_mcp";
      inherit version;
      hash = "sha256-BH3+LdZfZ/MU5AClmvuFB6GFa8CG5LvXcI9sm/bKavg=";
    };

    build-system = [ python3Packages.hatchling ];
    dependencies = with python3Packages; [
      mcp
      requests
    ];

    pythonImportsCheck = [ "cronometer_mcp.server" ];

    meta = {
      description = "Community MCP server for Cronometer nutrition data";
      homepage = "https://github.com/cphoskins/cronometer-mcp";
      license = lib.licenses.mit;
      mainProgram = "cronometer-mcp";
    };
  };

  service = "cronometer-mcp-server";
in
# The login is an email and password, read from the login keychain at
# start-up: one item under this service, with the email as the account
# and the password as the secret, matched on the service alone.
# Upstream's README puts both in the client's `env` block, which would
# leave the password in plain text.
#
# The server persists a pickled session cookie at
# `$CRONOMETER_DATA_DIR/.session_cookies`, so that is a live session
# token at rest. The caller sets that directory, because its default is
# a dotdir; it also receives `sync_cronometer` exports, which are health
# data.
#
# Unlike the Docker Hub server this one can do nothing without a login,
# so a missing credential is an error rather than a warning.
writeShellScriptBin "cronometer-mcp-server" (
  builtins.readFile (
    replaceVars ./cronometer-mcp-server/wrapper.sh {
      serviceArg = lib.escapeShellArg service;
      server = lib.getExe server;
      inherit service;
    }
  )
)
