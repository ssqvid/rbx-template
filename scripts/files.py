import json
import tomlkit
import sys
from typing import Any


def write_with_reject(file, data, dump):
    try:
        f = open(file, "x")
        dump(f, data)
        f.close()
    except FileExistsError:
        print(f"{file} already exists! Writing information to {file}.rej")
        try:
            f = open(".darklua.json.reject", "x")
            dump(f, data)
            f.close()
        except FileExistsError:
            f = open(".darklua.reject.json", "w")
            dump(f, data)
            f.close()


def dump_json(f, d):
    json.dump(d, f, indent=2)


def create_rojo_project(name, source, project_type):
    package_folder_name = "Packages" if project_type == "luau" else "include"
    package_tree = (
        {"$path": "roblox_packages"}
        if project_type == "luau"
        else {
            "$path": "include",
            "node_modules": {
                "$className": "Folder",
                "@rbxts": {
                    "$path": "node_modules/@rbxts",
                },
            },
        }
    )

    shared_name = "Shared" if project_type == "luau" else "TS"
    client_name = "Client" if project_type == "luau" else "TS"
    server_name = "Server" if project_type == "luau" else "TS"

    return {
        "name": name,
        "tree": {
            "$className": "DataModel",
            "ReplicatedStorage": {
                "$className": "ReplicatedStorage",
                shared_name: {
                    "$path": f"{source}/shared",
                    package_folder_name: package_tree,
                },
            },
            "StarterPlayer": {
                "$className": "StarterPlayer",
                "StarterPlayerScripts": {
                    "$className": "StarterPlayerScripts",
                    client_name: {
                        "$path": f"{source}/client",
                    },
                },
            },
            "ServerScriptService": {
                "$className": "ServerScriptService",
                server_name: {
                    "$path": f"{source}/server",
                },
            },
        },
    }


def darklua_base() -> list[Any]:
    return [
        "compute_expression",
        "convert_index_to_field",
        "filter_after_early_return",
        "remove_empty_do",
        "remove_interpolated_string",
        "remove_nil_declaration",
        "remove_unused_if_branch",
        "remove_unused_variable",
        "remove_unused_while",
    ]


def fix_luaurc():
    try:
        with open(".luaurc", "r") as luaurc:
            data = json.load(luaurc)
        data["languageMode"] = "nocheck"
        with open(".luaurc", "w") as luaurc:
            json.dump(data, luaurc, indent=2)
    except FileNotFoundError:
        pass


def fix_rokit():
    try:
        with open("rokit.toml", "r") as rokit:
            data = tomlkit.load(rokit)
        data["tools"].pop("darklua")
        data["tools"].pop("luau-lsp")
        data["tools"].pop("stylua")
        data["tools"].pop("selene")
        with open(".rokit.json", "w") as rokit:
            tomlkit.dump(data, rokit)
    except FileNotFoundError:
        pass


def fix_asphalt():
    try:
        with open("asphalt.toml", "r") as asphalt:
            data = tomlkit.load(asphalt)
        data["codegen"]["style"] = "nested"
        with open("asphalt.toml", "w") as asphalt:
            tomlkit.dump(data, asphalt)
    except FileNotFoundError:
        pass


def fix_configs(project_type):
    if project_type == "ts":
        fix_luaurc()
        fix_rokit()
    else:
        fix_asphalt()


def sign_files(author, project_name):
    try:
        with open("pesde.toml", "r") as pesde_manifest:
            data = tomlkit.load(pesde_manifest)
        data["name"] = f"{author}/{project_name}"
        with open("pesde.toml", "w") as pesde_manifest:
            tomlkit.dump(data, pesde_manifest)
    except FileNotFoundError:
        pass

    try:
        with open("project.json", "r") as project_manifest:
            data = json.load(project_manifest)
        data["name"] = f"{project_name}"
        with open("project.json", "w") as project_manifest:
            json.dump(data, project_manifest, indent=2)
    except FileNotFoundError:
        pass


def generate_sourcemap(project_type, author, project_name):
    name = f"{author}/{project_name}"
    source = "src" if project_type == "luau" else "out"

    rojoProject = create_rojo_project(name, source, project_type)
    write_with_reject("default.project.json", rojoProject, dump_json)

    if project_type == "luau":
        distProject = create_rojo_project(f"{name}@dist", "out", project_type)
        write_with_reject("dist.project.json", distProject, dump_json)


def generate_darklua(project_type):
    if project_type == "ts":
        return

    base_rules = darklua_base()
    write_with_reject(".darklua.json", {"rules": base_rules}, dump_json)

    if project_type == "luau":
        dist_rules = base_rules.copy()
        dist_rules.append(
            {
                "rule": "convert_require",
                "current": {
                    "name": "path",
                    "sources": {
                        "@pkg": "roblox_packages",
                    },
                },
                "target": {
                    "name": "roblox",
                    "rojo_sourcemap": "sourcemap.json",
                    "indexing_style": "property",
                },
            },
        )
        dist_rules.append("remove_assertions")
        write_with_reject("dist.darklua.json", {"rules": dist_rules}, dump_json)


if __name__ == "__main__":
    project_type = sys.argv[1]
    author = sys.argv[2]
    project_name = sys.argv[3]

    fix_configs(project_type)
    sign_files(author, project_name)
    generate_sourcemap(project_type, author, project_name)
    generate_darklua(project_type)
