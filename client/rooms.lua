--========================================================--
-- Standalone Hotel Framework
-- client/rooms.lua
--========================================================--

local CurrentRoom = nil
local InsideRoom = false
local LastExitCoords = nil

local function Notify(msg)
    TriggerEvent("hotel:notify", msg)
end

local function FindRoom(hotelId, roomId)
    for _, hotel in pairs(Config.Hotels or {}) do
        if hotel.id == hotelId and hotel.rooms then
            for _, room in pairs(hotel.rooms) do
                if tonumber(room.id) == tonumber(roomId) then
                    return room, hotel
                end
            end
        end
    end

    if Config.Rooms and Config.Rooms[hotelId] then
        for _, room in pairs(Config.Rooms[hotelId]) do
            if tonumber(room.id) == tonumber(roomId) then
                return room, { id = hotelId }
            end
        end
    end

    return nil, nil
end

local function FadeTeleport(coords, heading)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    local ped = PlayerPedId()

    SetEntityCoords(
        ped,
        coords.x,
        coords.y,
        coords.z,
        false,
        false,
        false,
        true
    )

    if heading then
        SetEntityHeading(ped, heading)
    end

    Wait(300)

    DoScreenFadeIn(500)
end

RegisterNetEvent("hotel:enterRoom", function(hotelId, roomId)
    TriggerServerEvent("hotel:checkRoomAccess", hotelId, roomId)
end)

RegisterNetEvent("hotel:roomAccessApproved", function(hotelId, roomId)
    local room = FindRoom(hotelId, roomId)

    if not room then
        Notify("Room location not configured.")
        return
    end

    local ped = PlayerPedId()
    LastExitCoords = GetEntityCoords(ped)

    local destination = room.inside or room.coords or room.entrance

    if type(destination) == "vector4" then
        FadeTeleport(
            vector3(destination.x, destination.y, destination.z),
            destination.w
        )
    else
        FadeTeleport(destination, room.heading)
    end

    InsideRoom = true
    CurrentRoom = {
        hotel = hotelId,
        room = roomId
    }

    Notify("You entered your hotel room.")
end)

RegisterNetEvent("hotel:roomAccessDenied", function()
    Notify("You do not have access to this room.")
end)

RegisterNetEvent("hotel:exitRoom", function(hotelId, roomId)
    local room = FindRoom(hotelId, roomId)

    local exitCoords =
        (room and room.outside)
        or LastExitCoords

    if not exitCoords then
        Notify("Exit location not configured.")
        return
    end

    if type(exitCoords) == "vector4" then
        FadeTeleport(
            vector3(exitCoords.x, exitCoords.y, exitCoords.z),
            exitCoords.w
        )
    else
        FadeTeleport(exitCoords)
    end

    InsideRoom = false
    CurrentRoom = nil

    Notify("You left the hotel room.")
end)

RegisterNetEvent("hotel:openStash", function(hotelId, roomId)
    if CurrentRoom
        and CurrentRoom.hotel == hotelId
        and tonumber(CurrentRoom.room) == tonumber(roomId)
    then
        TriggerServerEvent("hotel:openRoomStash", hotelId, roomId)
    else
        TriggerServerEvent("hotel:checkRoomAccess", hotelId, roomId, "stash")
    end
end)

RegisterNetEvent("hotel:openWardrobe", function(hotelId, roomId)
    if CurrentRoom
        and CurrentRoom.hotel == hotelId
        and tonumber(CurrentRoom.room) == tonumber(roomId)
    then
        TriggerEvent("hotel:wardrobeOpen", hotelId, roomId)
    else
        TriggerServerEvent("hotel:checkRoomAccess", hotelId, roomId, "wardrobe")
    end
end)

RegisterNetEvent("hotel:roomActionApproved", function(action, hotelId, roomId)
    if action == "stash" then
        TriggerServerEvent("hotel:openRoomStash", hotelId, roomId)
    elseif action == "wardrobe" then
        TriggerEvent("hotel:wardrobeOpen", hotelId, roomId)
    end
end)

RegisterCommand("hotel_room", function()
    if not CurrentRoom then
        Notify("You are not inside a hotel room.")
        return
    end

    Notify(
        ("Current room: %s / %s"):format(
            CurrentRoom.hotel,
            CurrentRoom.room
        )
    )
end)

exports("IsInsideHotelRoom", function()
    return InsideRoom
end)

exports("GetCurrentHotelRoom", function()
    return CurrentRoom
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    CurrentRoom = nil
    InsideRoom = false
    LastExitCoords = nil
end)
