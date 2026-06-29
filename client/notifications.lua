--========================================================--
-- Standalone Hotel Framework
-- client/notifications.lua
--========================================================--

Notifications = {}

--------------------------------------------------------
-- Detect Notification Resource
--------------------------------------------------------

local Provider = "standalone"

if GetResourceState("ox_lib") == "started" then
    Provider = "ox"

elseif GetResourceState("okokNotify") == "started" then
    Provider = "okok"

elseif GetResourceState("mythic_notify") == "started" then
    Provider = "mythic"

elseif GetResourceState("qb-core") == "started" then
    Provider = "qb"

elseif GetResourceState("es_extended") == "started" then
    Provider = "esx"

end

--------------------------------------------------------
-- Standalone GTA Notification
--------------------------------------------------------

local function GTA(message)

    BeginTextCommandThefeedPost("STRING")

    AddTextComponentSubstringPlayerName(message)

    EndTextCommandThefeedPostTicker(false, false)

end

--------------------------------------------------------
-- Main Notification
--------------------------------------------------------

function Notifications.Show(message, notifyType, duration)

    notifyType = notifyType or "inform"

    duration = duration or 5000

    ----------------------------------------------------
    -- ox_lib
    ----------------------------------------------------

    if Provider == "ox" then

        lib.notify({

            title = "Hotel",

            description = message,

            type = notifyType,

            duration = duration

        })

        return

    end

    ----------------------------------------------------
    -- okokNotify
    ----------------------------------------------------

    if Provider == "okok" then

        exports.okokNotify:Alert(

            "Hotel",

            message,

            duration,

            notifyType

        )

        return

    end

    ----------------------------------------------------
    -- Mythic Notify
    ----------------------------------------------------

    if Provider == "mythic" then

        exports["mythic_notify"]:SendAlert(

            notifyType,

            message,

            duration

        )

        return

    end

    ----------------------------------------------------
    -- QB
    ----------------------------------------------------

    if Provider == "qb" then

        TriggerEvent(

            "QBCore:Notify",

            message,

            notifyType,

            duration

        )

        return

    end

    ----------------------------------------------------
    -- ESX
    ----------------------------------------------------

    if Provider == "esx" then

        TriggerEvent(

            "esx:showNotification",

            message

        )

        return

    end

    ----------------------------------------------------
    -- Standalone
    ----------------------------------------------------

    GTA(message)

end

--------------------------------------------------------
-- Convenience Functions
--------------------------------------------------------

function Notifications.Success(msg)

    Notifications.Show(msg, "success")

end

function Notifications.Error(msg)

    Notifications.Show(msg, "error")

end

function Notifications.Warning(msg)

    Notifications.Show(msg, "warning")

end

function Notifications.Info(msg)

    Notifications.Show(msg, "inform")

end

--------------------------------------------------------
-- Announcement
--------------------------------------------------------

function Notifications.Announcement(title, msg)

    Notifications.Show(

        ("~b~%s~s~\n%s"):format(title, msg),

        "inform",

        8000

    )

end

--------------------------------------------------------
-- Progress Bar (ox_lib)
--------------------------------------------------------

function Notifications.Progress(label, duration)

    if Provider ~= "ox" then
        return false
    end

    return lib.progressBar({

        duration = duration,

        label = label,

        useWhileDead = false,

        canCancel = false,

        disable = {

            move = true,

            combat = true,

            vehicle = true

        }

    })

end

--------------------------------------------------------
-- Events
--------------------------------------------------------

RegisterNetEvent("hotel:notify", function(msg)

    Notifications.Info(msg)

end)

RegisterNetEvent("hotel:notifySuccess", function(msg)

    Notifications.Success(msg)

end)

RegisterNetEvent("hotel:notifyError", function(msg)

    Notifications.Error(msg)

end)

RegisterNetEvent("hotel:notifyWarning", function(msg)

    Notifications.Warning(msg)

end)

--------------------------------------------------------
-- Exports
--------------------------------------------------------

exports("Notify", Notifications.Show)

exports("Success", Notifications.Success)

exports("Error", Notifications.Error)

exports("Warning", Notifications.Warning)

exports("Info", Notifications.Info)

exports("Announcement", Notifications.Announcement)

exports("Progress", Notifications.Progress)
