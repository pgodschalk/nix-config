# Python package overrides that give cronometer-mcp the MCP SDK 2 it
# requires while nixpkgs still ships SDK 1. They apply only to the
# interpreter cronometer-mcp-server.nix builds, so nothing else sees
# them.
#
# Built from PyPI's pure-Python wheels: upstream's source builds are uv
# workspaces with dynamic dependencies, and mcp 2 needs a newer httpx2
# and httpcore2 than nixpkgs has, which share one monorepo. Drop this
# file once nixpkgs' mcp reaches what cronometer-mcp asks for.
{ lib }:
self: super:
let
  wheel =
    {
      pname,
      version,
      hash,
      dependencies,
      homepage,
      license,
    }:
    self.buildPythonPackage {
      inherit pname version dependencies;
      format = "wheel";
      src = self.fetchPypi {
        pname = lib.replaceStrings [ "-" ] [ "_" ] pname;
        inherit version hash;
        format = "wheel";
        dist = "py3";
        python = "py3";
      };
      pythonImportsCheck = [ (lib.replaceStrings [ "-" ] [ "_" ] pname) ];
      meta = {
        inherit homepage license;
      };
    };
in
{
  httpcore2 = wheel {
    pname = "httpcore2";
    # @VERSION https://pypi.org/project/httpcore2/#history
    version = "2.13.1";
    hash = "sha256-4eBdTyX319SWv7lnSPb0tnZXsD2gabOmjDYGnz23PQo=";
    dependencies = with self; [
      anyio
      h11
      truststore
    ];
    homepage = "https://github.com/pydantic/httpx2";
    license = lib.licenses.bsd3;
  };

  # Must match httpcore2's version: httpx2 pins it exactly.
  httpx2 = wheel {
    pname = "httpx2";
    # @VERSION https://pypi.org/project/httpx2/#history
    version = "2.13.1";
    hash = "sha256-bf9Q+rwnDuX9JdhF0LB47SBWRXl0TW2WKFCXWZbS+aQ=";
    dependencies = with self; [
      anyio
      httpcore2
      idna
      truststore
    ];
    homepage = "https://github.com/pydantic/httpx2";
    license = lib.licenses.bsd3;
  };

  # Must match mcp's version: mcp pins it exactly.
  mcp-types = wheel {
    pname = "mcp-types";
    # @VERSION https://pypi.org/project/mcp-types/#history
    version = "2.3.0";
    hash = "sha256-lo79va7fqwatrkDTeKNDlfEJDFkh1L48nN4oOq922R0=";
    dependencies = with self; [
      pydantic
      typing-extensions
    ];
    homepage = "https://github.com/modelcontextprotocol/python-sdk";
    license = lib.licenses.mit;
  };

  mcp = wheel {
    pname = "mcp";
    # @VERSION https://pypi.org/project/mcp/#history
    version = "2.3.0";
    hash = "sha256-3QxEwInRZFPorjGjh3oAVNeiMUyqqB9eBUG5sXNLI3c=";
    dependencies =
      with self;
      [
        anyio
        httpx2
        jsonschema
        mcp-types
        opentelemetry-api
        pydantic
        pyjwt
        python-multipart
        sse-starlette
        starlette
        typing-extensions
        typing-inspection
        uvicorn
      ]
      ++ self.pyjwt.optional-dependencies.crypto;
    homepage = "https://github.com/modelcontextprotocol/python-sdk";
    license = lib.licenses.mit;
  };
}
