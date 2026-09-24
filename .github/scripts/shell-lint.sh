#!/usr/bin/env bash

set -euo pipefail

git ls-files '*.sh' | xargs shellcheck
