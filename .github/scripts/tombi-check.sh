#!/usr/bin/env bash

set -euo pipefail

git ls-files '*.toml' | xargs tombi "$@"
