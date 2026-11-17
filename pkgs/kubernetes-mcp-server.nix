# The Kubernetes MCP server, from the upstream release binary. The npm
# package of the same name is a node shim that spawns this binary.
{ lib, callPackage }:

let
  # @VERSION https://github.com/containers/kubernetes-mcp-server/releases
  version = "0.1.3";
  base = "https://github.com/containers/kubernetes-mcp-server/releases/download/v${version}";
in
callPackage ./lib/release-binary.nix { } {
  pname = "kubernetes-mcp-server";
  inherit version;

  assets = {
    aarch64-darwin = {
      url = "${base}/kubernetes-mcp-server-darwin-arm64";
      hash = "sha256-2ifFSwvb9LisR9u3yjzwaaNtZGheA05KvPF/1wFeR7Q=";
    };
    aarch64-linux = {
      url = "${base}/kubernetes-mcp-server-linux-arm64";
      hash = "sha256-Ji0/PXgAuIV0tr4wwctGY/gUgfoSvUHgLBDUOmYGnT4=";
    };
    x86_64-linux = {
      url = "${base}/kubernetes-mcp-server-linux-amd64";
      hash = "sha256-Nj5Dp9hlrS1If4ioJ7fTfN1bVrTKb9hq/80OIxpBBKY=";
    };
  };

  meta = {
    description = "MCP server for Kubernetes and OpenShift";
    homepage = "https://github.com/containers/kubernetes-mcp-server";
    license = lib.licenses.asl20;
  };
}
