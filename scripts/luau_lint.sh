#! /usr/bin/env bash

# This script is used to check a Roblox project.

if [ ! -e "globalTypes.d.luau" ] then
    chmod +x ./scripts/luau_defs.sh
    ./scripts/luau_defs.sh 1 0
fi

blink .blink/init -y
rojo sourcemap default.project.json -o sourcemap.json

selene .
stylua --check .
luau-lsp analyze \
    --platform roblox \
    --no-strict-dm-types \
    --base-luaurc .luaurc \
    --defs globalTypes.d.luau \
    --sourcemap sourcemap.json \
    --ignore "*.d.luau" \
    --ignore "**/network/**" \
    --ignore "**/roblox_packages/**" \
    --ignore "**/lune_packages/**" \
    --ignore "**/luau_packages/**" \
    --ignore "**/.pesde/**" \
    .
