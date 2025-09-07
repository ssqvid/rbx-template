#! /usr/bin/env bash

# This script is used to initialize a new Roblox project.
# Configuration files by default are set to the language they are meant for.
# This script will modify some configuration files to work with the other language. (ts specifically)

# Ask the user for information about the project.
if [ -d "src" ]; then
    echo "src directory already exists. Please delete it and try again."
    exit 1
fi

read -p "Is this a luau or typescript project? [luau/ts]: " project_type
while [[ $project_type != "luau" && $project_type != "ts" ]]; do
    read -p "Try Again! Is this a luau or typescript project? [luau/ts]: " project_type
done
read -p "Did you check your dependencies? [y/n]: " valid_deps
while [[ $valid_deps != "y" && $valid_deps != "yes" ]]; do
    read -p "Try Again! Did you check your dependencies? [y/n]: " valid_deps
done
read -p "Enter the author's name: " author_name
author_name=${author_name// /}
if [[ $project_type == "luau" ]]; then
    while [[ ${#author_name} -lt 3 || ${#author_name} -gt 32 ]]; do
        read -p "Try Again! Enter the author's name: " author_name
        author_name=${author_name// /}
    done
fi
read -p "Enter the name of your project: " project_name
project_name=${project_name// /}

# Python should be kept in the directory as it is a good utility for editing assets.
#
# Rename manifests and project files.
if [ ! -d ".venv" ]; then
    python3 -m venv .venv > /dev/null
fi
source .venv/bin/activate > /dev/null
pip install tomlkit > /dev/null
python ./scripts/files.py $project_type $author_name $project_name
deactivate

# Set github actions.
if [[ $project_type == "luau" ]]; then
    mv .github/workflows/ci-cd-luau.yml .github/workflows/ci-cd.yml
    rm -f .github/workflows/ci-cd-ts.yml
else
    mv .github/workflows/ci-cd-ts.yml .github/workflows/ci-cd.yml
    rm -f .github/workflows/ci-cd-luau.yml
fi

# Install necessary tooling.
if [[ $project_type == "ts" ]]; then
    rokit add lune
fi

rokit install

if [ -e "globalTypes.d.luau" ]; then
    rm -f globalTypes.d.luau
fi

if [ -e "api-docs.json" ]; then
    rm -f api-docs.json
fi

if [[ $project_type == "luau" ]]; then
    chmod +x ./scripts/luau_defs.sh
    ./scripts/luau_defs.sh
fi

# Initialize the project source files.
if [[ $project_type == "luau" ]]; then
    mkdir __temp__
    cd ./__temp__
    rojo init > /dev/null
    mv ./src ../src
    cd ..
    rm -rf ./__temp__
else
    mkdir -p src/{shared,server,client}

    touch src/shared/module.ts
    echo "export function makeHello(name: string) {
    return \`Hello from \${name}!\`;
}" >> src/shared/module.ts

    touch src/server/main.server.ts
    echo "import { makeHello } from \"shared/module\";

print(makeHello(\"main.server.ts\"));" >> src/server/main.server.ts

    touch src/client/main.client.ts
    echo "import { makeHello } from \"shared/module\";

print(makeHello(\"main.client.ts\"));" >> src/client/main.client.ts
fi

# Install necessary tooling.
if [[ $project_type == "luau" ]]; then
    if [ $(uname) == "Linux" ]; then 
        echo "PESDE WILL NOT THROW ERRORS ON LINUX DUE TO A TERRIBLE SOURCEMAP BUG"
        pesde install 2> /dev/null
    else
        pesde install
    fi
else
    pnpm install
fi

# Remove unnecessary files.
if [[ $project_type == "luau" ]]; then
    rm -f .prettierrc
    rm -f eslint.config.ts
    rm -f package.json
    rm -f tsconfig.json
fi

# Build the project.
if [[ $project_type == "luau" ]]; then
    chmod +x ./scripts/luau_dist.sh
    ./scripts/luau_dist.sh
else
    pnpm run build
fi

exit 0
