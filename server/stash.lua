--========================================================--
-- Standalone Hotel Framework
-- server/stash.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Stash = Hotel.Stash or {}

Hotel.Stash.Type = "standalone"

if GetResourceState("ox_inventory") == "started" then
    Hotel.Stash.Type = "ox"
elseif GetResourceState("qb-inventory") == "started" then
    Hotel.Stash.Type = "qb"
elseif GetResourceState("qs-inventory") == "started" then
    Hotel.Stash.Type = "qs"
end

function Hotel.Stash.GetId(hotelId, roomId)
    return ("hotel_%s_%s"):format(hotelId, tonumber(roomId))
end

function Hotel.Stash.Register(hotelId, room)
    if not room then return false end

    local stashId = Hotel.Stash.GetId(hotelId, room.id)
    local label = room.label or ("Hotel Room %s"):format(room.id)
    local slots = room.stashSlots or Config.StashSlots or 30
    local weight = room.stashWeight or Config.StashWeight or 50000

    if Hotel.Stash.Type == "ox" then
        exports.ox_inventory:RegisterStash(stashId, label, slots, weight, false)
        return true
    end

    return true
end

function Hotel.Stash.RegisterAll()
    for _, hotel in pairs(Config.Hotels or {}) do
        local rooms = hotel.rooms or (Config.Rooms and Config.Rooms[hotel.id]) or {}

        for _, room in pairs(rooms) do
            if room.stash then
                Hotel.Stash.Register(hotel.id, room)
            end
        end
    end
end

RegisterNetEvent("hotel:requestStashAccess", function(hotelId, roomId)
    local src = source

    if not exports[GetCurrentResourceName()]:HasRoomAccess(src, hotelId, tonumber(roomId)) then
        return Hotel.Notify(src, "You don't have access to this stash.", "error")
    end

    TriggerClientEvent("hotel:stashApproved", src, hotelId, tonumber(roomId))
end)

CreateThread(function()
    Wait(2000)
    Hotel.Stash.RegisterAll()
end)

exports("GetHotelStashId", Hotel.Stash.GetId)
exports("RegisterHotelStash", Hotel.Stash.Register)
exports("RegisterAllHotelStashes", Hotel.Stash.RegisterAll)
