# Google's gcloud MCP server. Not in nixpkgs; built from the published
# npm tarball, a bundle that imports only node's built-ins. It runs
# `gcloud` from PATH, so its identity is the caller's CLOUDSDK_CONFIG.
{ lib, callPackage }:

let
  # @VERSION https://www.npmjs.com/package/@google-cloud/gcloud-mcp
  version = "0.5.3";
in
callPackage ./lib/bun-package.nix { } {
  pname = "gcloud-mcp";
  npmName = "@google-cloud/gcloud-mcp";
  inherit version;
  hash = "sha256-Q2ujZBp7PH+wS7RASl1y0uWJFk42NHSLnhBpl9206to=";
  entry = "dist/bundle.js";

  meta = {
    description = "MCP server that runs gcloud commands";
    homepage = "https://github.com/googleapis/gcloud-mcp";
    license = lib.licenses.asl20;
  };
}
