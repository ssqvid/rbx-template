#! /bin/bash

# This script is used to distribute a Roblox project.

darklua process src src -c .darklua.json
stylua src
blink .blink/init -y
rojo sourcemap -o sourcemap.json
darklua process src out -c dist.darklua.json
rojo build dist.project.json -o dist.rbxl
