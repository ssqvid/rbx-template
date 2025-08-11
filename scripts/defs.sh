#! /bin/bash

# This script is used to load lsp files.
curl \
    -L "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/refs/heads/main/scripts/globalTypes.d.luau" \
    -O
curl \
    -L https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/api-docs/en-us.json \
    -O
