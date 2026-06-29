local Notify = require "client.notifications"
local Utils  = require "client.utils"

local Keys             = {}
local UsingOxInventory = GetResourceState("ox_inventory") == "started"

local function KeyIndex(hotelId, roomId)
    for i = 1, #Keys do
        local key = Keys[i]
        if key.hotel == hotelId and key.room == roomId then return i end
    end
    return nil
end

local function HasKey(hotelId, roomId)
    local now = os.time()
    for _, key in pairs(Keys) do
        if key.hotel == hotelId and key.room == roomId then
            if not key.expires or key.expires > now then return true end
        end
    end
    return false
end

RegisterNetEvent("hotel:receiveKey", function(data)
    if not data then return end
    local index = KeyIndex(data.hotel, data.room)
    if index then
        Keys[index] = data
    else
        Keys[#Keys + 1] = data
    end
    Notify.Success(("Received key for Room %s"):format(data.room))
end)

RegisterNetEvent("hotel:removeKey", function(hotelId, roomId)
    local index = KeyIndex(hotelId, roomId)
    if not index then return end
    table.remove(Keys, index)
    Notify.Info("Hotel key removed.")
end)

RegisterNetEvent("hotel:syncKeys", function(serverKeys)
    Keys = serverKeys or {}
end)

RegisterCommand("hotelkey", function(_, args)
    local room = tonumber(args[1])
    if not room then Notify.Info("/hotelkey [roomId]") return end

    for _, key in pairs(Keys) do
        if key.room == room then
            local granted = lib.callback.await("hotel:requestRoomEntry", false, key.hotel, key.room)
            if not granted then Notify.Error("You don't own this room key.") end
            return
        end
    end

    Notify.Error("You don't own that room key.")
end)

if UsingOxInventory then
    CreateThread(function()
        Wait(3000)
        while true do
            Wait(30000)
            local items = exports.ox_inventory:Search("slots", "hotel_key")
            Keys = {}
            for _, item in pairs(items or {}) do
                if item.metadata then
                    Keys[#Keys + 1] = {
                        hotel   = item.metadata.hotel,
                        room    = item.metadata.room,
                        expires = item.metadata.expires,
                    }
                end
            end
        end
    end)
end

CreateThread(function()
    while true do
        Wait(60000)
        local now = os.time()
        for i = #Keys, 1, -1 do
            if Keys[i].expires and Keys[i].expires <= now then
                Notify.Info(("Room %s key expired"):format(Keys[i].room))
                table.remove(Keys, i)
            end
        end
    end
end)

AddEventHandler("onClientResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    TriggerServerEvent("hotel:syncKeys")
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Keys = {}
end)

RegisterCommand("hotelkeys", function()
    for _, key in pairs(Keys) do print(json.encode(key)) end
end)

exports("HasHotelKey",  HasKey)
exports("GetHotelKeys", function() return Keys end)
