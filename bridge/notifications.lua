--========================================================--
-- Standalone Hotel Framework
-- bridge/notifications.lua
--========================================================--

Bridge = Bridge or {}
Bridge.Notifications = Bridge.Notifications or {}

Bridge.Notifications.Type = "standalone"

if GetResourceState("ox_lib") == "started" then
    Bridge.Notifications.Type = "ox"
elseif GetResourceState("okokNotify") == "started" then
    Bridge.Notifications.Type = "okok"
elseif GetResourceState("mythic_notify") == "started" then
    Bridge.Notifications.Type = "mythic"
elseif GetResourceState("qb-core") == "started" then
    Bridge.Notifications.Type = "qb"
elseif GetResourceState("es_extended") == "started" then
    Bridge.Notifications.Type = "esx"
end

function Bridge.Notifications.Send(src, message, notifyType, duration)
    notifyType = notifyType or "inform"
    duration = duration or 5000

    TriggerClientEvent("hotel:notify", src, message, notifyType, duration)
end

function Bridge.Notifications.Success(src, message)
    Bridge.Notifications.Send(src, message, "success")
end

function Bridge.Notifications.Error(src, message)
    Bridge.Notifications.Send(src, message, "error")
end

function Bridge.Notifications.Warning(src, message)
    Bridge.Notifications.Send(src, message, "warning")
end

function Bridge.Notifications.Info(src, message)
    Bridge.Notifications.Send(src, message, "inform")
end

exports("Notify", Bridge.Notifications.Send)
exports("NotifySuccess", Bridge.Notifications.Success)
exports("NotifyError", Bridge.Notifications.Error)
exports("NotifyWarning", Bridge.Notifications.Warning)
exports("NotifyInfo", Bridge.Notifications.Info)
exports("NotificationType", function()
    return Bridge.Notifications.Type
end)
