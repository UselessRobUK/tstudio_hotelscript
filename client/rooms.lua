local Utils  = require "client.utils"
local Notify = require "client.notifications"

local CurrentRoom    = nil
local InsideRoom     = false
local LastExitCoords = nil

local function EnterRoom(hotelId, roomId)
    local granted = lib.callback.await("hotel:checkRoomAccess", false, hotelId, roomId)
    if not granted then return Notify.Info("You do not have access to this room.") end

    local room = Utils.FindRoom(hotelId, roomId)
    if not room then return Notify.Info("Room location not configured.") end

    local ped = PlayerPedId()
    LastExitCoords = GetEntityCoords(ped)

    local dest = room.inside or room.coords or room.entrance
    if type(dest) == "vector4" then
        Utils.FadeTeleport(vector3(dest.x, dest.y, dest.z), dest.w)
    else
        Utils.FadeTeleport(dest, room.heading)
    end

    InsideRoom  = true
    CurrentRoom = { hotel = hotelId, room = roomId }
    Notify.Info("You entered your hotel room.")
end

RegisterNetEvent("hotel:enterRoom", function(hotelId, roomId)
    EnterRoom(hotelId, roomId)
end)

RegisterNetEvent("hotel:exitRoom", function(hotelId, roomId)
    local room       = Utils.FindRoom(hotelId, roomId)
    local exitCoords = (room and room.outside) or LastExitCoords
    if not exitCoords then return Notify.Info("Exit location not configured.") end

    if type(exitCoords) == "vector4" then
        Utils.FadeTeleport(vector3(exitCoords.x, exitCoords.y, exitCoords.z), exitCoords.w)
    else
        Utils.FadeTeleport(exitCoords)
    end

    InsideRoom  = false
    CurrentRoom = nil
    Notify.Info("You left the hotel room.")
end)

RegisterNetEvent("hotel:openStash", function(hotelId, roomId)
    local inRoom = CurrentRoom and CurrentRoom.hotel == hotelId and tonumber(CurrentRoom.room) == tonumber(roomId)
    if not inRoom then
        local granted = lib.callback.await("hotel:checkRoomAccess", false, hotelId, roomId)
        if not granted then return Notify.Info("You do not have access to this room.") end
    end
    TriggerServerEvent("hotel:openRoomStash", hotelId, roomId)
end)

RegisterNetEvent("hotel:openWardrobe", function(hotelId, roomId)
    local inRoom = CurrentRoom and CurrentRoom.hotel == hotelId and tonumber(CurrentRoom.room) == tonumber(roomId)
    if not inRoom then
        local granted = lib.callback.await("hotel:checkRoomAccess", false, hotelId, roomId)
        if not granted then return Notify.Info("You do not have access to this room.") end
    end
    TriggerEvent("hotel:wardrobeOpen", hotelId, roomId)
end)

RegisterCommand("hotel_room", function()
    if not CurrentRoom then Notify.Info("You are not inside a hotel room.") return end
    Notify.Info(("Current room: %s / %s"):format(CurrentRoom.hotel, CurrentRoom.room))
end)

exports("IsInsideHotelRoom",   function() return InsideRoom end)
exports("GetCurrentHotelRoom", function() return CurrentRoom end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    CurrentRoom    = nil
    InsideRoom     = false
    LastExitCoords = nil
end)
