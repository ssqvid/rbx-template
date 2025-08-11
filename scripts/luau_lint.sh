#! /bin/bash

# This script is used to check a Roblox project.

rokit install
if [ ! -e "globalTypes.d.luau" ] || [ ! -e "en-us.json" ]; then
    ./scripts/defs.sh
fi
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
