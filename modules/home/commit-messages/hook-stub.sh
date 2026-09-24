#!/bin/sh
exec @chainLocal@ "$(basename "$0")" "$@"
