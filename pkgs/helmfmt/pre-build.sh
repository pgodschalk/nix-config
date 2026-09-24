# shellcheck shell=bash

# `sprig_stubs.go` is generated and gitignored, so a plain build of the
# tag fails with `undefined: sprigStubNames`. `go generate` is the
# documented route; `gen_stubs.go` is the same generator run directly,
# for a tag whose directive has moved or gone.
go generate ./... || go run gen_stubs.go
