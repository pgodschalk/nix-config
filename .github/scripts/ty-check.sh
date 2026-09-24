#!/usr/bin/env bash

set -euo pipefail

ty=$(.github/scripts/nix-tool.sh ty)
"$ty" check
