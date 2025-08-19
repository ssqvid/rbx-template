#! /usr/bin/env bash

# This script is used to load lsp files.
if (( $1 == 1 )); then
    curl \
        -L "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/refs/heads/main/scripts/globalTypes.d.luau" \
        -O
fi
if (( $2 == 1 )); then
    curl \
        -L https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/api-docs/en-us.json \
        -o api-docs.json
fi
