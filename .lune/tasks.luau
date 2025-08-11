local tasks = {}

local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")
local task = require("@lune/task")

local function MakeRequest(config: net.FetchParams): net.FetchResponse
    local result: net.FetchResponse

    if not config.method then
        config.method = (config.body and "POST") or "GET"
    end

    local attempts = 3

    for i = 1, attempts do
        result = net.request(config)

        if result.ok then
            break
        end

        if i == attempts then
            error(result.statusMessage)
        end

        stdio.write(string.format("Retrying error: %s\n", result.statusMessage))
        task.wait(1)
    end

    return result
end

function tasks.Create(
    apiKey: string,
    universeID: string,
    placeID: string,
    placeVersion: string,
    taskPath: string
): any
    local response = MakeRequest {
        url = string.format(
            "https://apis.roblox.com/cloud/v2/universes/%s/places/%s/%sluau-execution-session-tasks",
            universeID,
            placeID,
            (placeVersion and string.format("versions/%s/", placeVersion)) or ""
        ),
        headers = {
            ["Content-Type"] = "application/json",
            ["x-api-key"] = apiKey,
        } :: net.HttpHeaderMap,
        body = serde.encode("json", {
            script = fs.readFile(taskPath),
        }),
    }

    return serde.decode("json", response.body)
end

function tasks.PollForCompletion(apiKey: string, taskPath: string): any
    stdio.write(string.format("Polling task @ %s...", taskPath))

    while true do
        local response = MakeRequest {
            url = string.format("https://apis.roblox.com/cloud/v2/%s", taskPath),
            headers = {
                ["x-api-key"] = apiKey,
            } :: net.HttpHeaderMap,
        }

        if not response.ok then
            error(string.format("Get task request failed, status:\n%s", response.statusMessage))
        end

        local taskInfo = serde.decode("json", response.body)
        if taskInfo["state"] ~= "PROCESSING" then
            return taskInfo
        else
            task.wait(3)
        end
    end
end

function tasks.GetLogs(apiKey: string, taskPath: string): string
    local response = MakeRequest {
        url = string.format("https://apis.roblox.com/cloud/v2/%s/logs", taskPath),
        headers = {
            ["x-api-key"] = apiKey,
        } :: net.HttpHeaderMap,
    }

    if not response.ok then
        error(string.format("Get task request failed, status:\n%s", response.statusMessage))
    end

    local taskLogs = serde.decode("json", response.body)
    local messages = taskLogs["luauExecutionSessionTaskLogs"][1]["messages"]

    local result = ""
    for _, m in ipairs(messages) do
        result = result .. m .. "\n"
    end
    return result
end

return tasks
