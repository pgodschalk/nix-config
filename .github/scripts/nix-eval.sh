#!/usr/bin/env bash

# Forces a full evaluation of the flake attribute named in $1 without
# building the configuration itself; fetched sources read at evaluation
# time are still realised. The `work` input is a private tree that exists on
# no runner, so the stub stands in for it.
set -euo pipefail

nix eval --raw --override-input work path:./stubs/work "$1"
