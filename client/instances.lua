local Notify = require "client.notifications"
local Utils  = require "client.utils"

local Instance = {
    active       = false,
    id           = nil,
    hotelId      = nil,
    roomId       = nil,
    returnCoords = nil,
}

RegisterNetEvent("hotel:enterInstance", function(data)
    if not data then return end

    local ped = PlayerPedId()

    Instance.active = true
    Instance.id = data.instanceId
    Instance.hotelId = data.hotelId
    Instance.roomId = data.roomId
    Instance.returnCoords = GetEntityCoords(ped)

    local coords = data.coords or vector4(-786.0, 315.0, 217.0, 0.0)

    Utils.FadeTeleport(coords, coords.w)

    NetworkSetVoiceChannel(tonumber(data.voiceChannel) or 0)

    Notify.Info("Entered private hotel room.")
end)

RegisterNetEvent("hotel:leaveInstance", function(data)
    local coords = data and data.coords or Instance.returnCoords

    if coords then
        Utils.FadeTeleport(coords, coords.w)
    end

    NetworkClearVoiceChannel()

    Instance.active = false
    Instance.id = nil
    Instance.hotelId = nil
    Instance.roomId = nil
    Instance.returnCoords = nil

    Notify.Info("Left private hotel room.")
end)

RegisterNetEvent("hotel:updateInstancePlayers", function(players)
    SendNUIMessage({
        action = "instancePlayers",
        data = players or {}
    })
end)

RegisterCommand("hotel_leaveinstance", function()
    if not Instance.active then
        Notify.Info("You are not inside a hotel instance.")
        return
    end

    TriggerServerEvent("hotel:requestLeaveInstance", Instance.id)
end)

exports("IsInHotelInstance", function()
    return Instance.active
end)

exports("GetHotelInstance", function()
    return {
        active = Instance.active,
        id = Instance.id,
        hotel = Instance.hotelId,
        room = Instance.roomId
    }
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if Instance.active and Instance.returnCoords then
        SetEntityCoords(
            PlayerPedId(),
            Instance.returnCoords.x,
            Instance.returnCoords.y,
            Instance.returnCoords.z,
            false,
            false,
            false,
            true
        )
    end

    NetworkClearVoiceChannel()
end)
