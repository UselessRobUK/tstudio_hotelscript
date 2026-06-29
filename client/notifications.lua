local provider = "standalone"

if GetResourceState("ox_lib") == "started" then
    provider = "ox"
elseif GetResourceState("okokNotify") == "started" then
    provider = "okok"
elseif GetResourceState("mythic_notify") == "started" then
    provider = "mythic"
elseif GetResourceState("qb-core") == "started" then
    provider = "qb"
elseif GetResourceState("es_extended") == "started" then
    provider = "esx"
end

local function GTA(message)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

---@param message string
---@param notifyType? string
---@param duration? number
local function Show(message, notifyType, duration)
    notifyType = notifyType or "inform"
    duration   = duration or 5000

    if provider == "ox" then
        lib.notify({ title = "Hotel", description = message, type = notifyType, duration = duration })
        return
    end
    if provider == "okok" then
        exports.okokNotify:Alert("Hotel", message, duration, notifyType)
        return
    end
    if provider == "mythic" then
        exports["mythic_notify"]:SendAlert(notifyType, message, duration)
        return
    end
    if provider == "qb" then
        TriggerEvent("QBCore:Notify", message, notifyType, duration)
        return
    end
    if provider == "esx" then
        TriggerEvent("esx:showNotification", message)
        return
    end
    GTA(message)
end

local function Success(msg)  Show(msg, "success") end
local function Error(msg)    Show(msg, "error") end
local function Warning(msg)  Show(msg, "warning") end
local function Info(msg)     Show(msg, "inform") end

local function Announcement(title, msg)
    Show(("~b~%s~s~\n%s"):format(title, msg), "inform", 8000)
end

local function Progress(label, duration)
    if provider ~= "ox" then return false end
    return lib.progressBar({
        duration     = duration,
        label        = label,
        useWhileDead = false,
        canCancel    = false,
        disable      = { move = true, combat = true, vehicle = true },
    })
end

RegisterNetEvent("hotel:notify",        function(msg, t, d) Show(msg, t, d) end)
RegisterNetEvent("hotel:notifySuccess", function(msg) Success(msg) end)
RegisterNetEvent("hotel:notifyError",   function(msg) Error(msg) end)
RegisterNetEvent("hotel:notifyWarning", function(msg) Warning(msg) end)
RegisterNetEvent("hotel:announcement",  function(title, msg) Announcement(title, msg) end)

exports("Notify",        Show)
exports("Success",       Success)
exports("Error",         Error)
exports("Warning",       Warning)
exports("Info",          Info)
exports("Announcement",  Announcement)
exports("Progress",      Progress)

return { Show = Show, Success = Success, Error = Error, Warning = Warning, Info = Info, Announcement = Announcement, Progress = Progress }
