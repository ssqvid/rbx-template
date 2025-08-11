local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

local tasks = require("./tasks")

local ROBLOX_API_KEY = process.env.ROBLOX_API_KEY :: string
local ROBLOX_UNIVERSE_ID = process.env.ROBLOX_UNIVERSE_ID :: string
local ROBLOX_PLACE_ID = process.env.ROBLOX_PLACE_ID :: string

local function uploadPlace(
    path: string,
    universeID: string,
    placeID: string,
    publish: true | nil
): string
    local response = net.request {
        url = string.format(
            "https://apis.roblox.com/universes/v1/%s/places/%s/versions?versionType=%s",
            universeID,
            placeID,
            (publish and "Published") or "Saved" -- Version type for upload.
        ),
        method = "POST",
        headers = {
            ["x-api-key"] = ROBLOX_API_KEY,
            ["Content-Type"] = "application/xml",
            Accept = "application/json",
        } :: net.HttpHeaderMap,
        body = fs.readFile(path),
    }

    local result = serde.decode("json", response.body)

    return result.versionNumber :: string
end

local function runTask(
    universeID: string,
    placeID: string,
    placeVersion: string,
    scriptPath: string
): ()
    local newTask = tasks.Create(ROBLOX_API_KEY, universeID, placeID, placeVersion, scriptPath)
    newTask = tasks.PollForCompletion(ROBLOX_API_KEY, newTask["path"])
    local logs = tasks.GetLogs(ROBLOX_API_KEY, newTask["path"])

    stdio.write(logs)

    if newTask["state"] == "COMPLETE" then
        process.exit(0)
    else
        process.exit(1)
    end
end

local binaryFile, scriptFile = process.args[1], process.args[2]
local placeVersion = uploadPlace(binaryFile, ROBLOX_UNIVERSE_ID, ROBLOX_PLACE_ID)
runTask(ROBLOX_UNIVERSE_ID, ROBLOX_PLACE_ID, placeVersion, scriptFile)
