# shellcheck shell=bash

printf >&2 'configuring diagnostics submission...\n'
defaults write @plist@ AutoSubmit -bool false
defaults write @plist@ ThirdPartyDataSubmit -bool false
