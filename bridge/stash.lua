--========================================================--
-- Standalone Hotel Framework
-- bridge/stash.lua
--========================================================--

Bridge = Bridge or {}
Bridge.Stash = Bridge.Stash or {}

Bridge.Stash.Type = "standalone"

if GetResourceState("ox_inventory") == "started" then
    Bridge.Stash.Type = "ox"
elseif GetResourceState("qb-inventory") == "started" then
    Bridge.Stash.Type = "qb"
elseif GetResourceState("qs-inventory") == "started" then
    Bridge.Stash.Type = "qs"
end

function Bridge.Stash.GetId(hotelId, roomId)
    return ("hotel_%s_%s"):format(hotelId, tonumber(roomId))
end

function Bridge.Stash.Register(hotelId, room)
    local stashId = Bridge.Stash.GetId(hotelId, room.id)
    local label = room.label or ("Hotel Room %s"):format(room.id)
    local slots = room.stashSlots or Config.StashSlots or 30
    local weight = room.stashWeight or Config.StashWeight or 50000

    if Bridge.Stash.Type == "ox" then
        exports.ox_inventory:RegisterStash(stashId, label, slots, weight, false)
        return true
    end

    return true
end

function Bridge.Stash.Open(src, hotelId, roomId)
    TriggerClientEvent("hotel:stashApproved", src, hotelId, tonumber(roomId))
    return true
end

function Bridge.Stash.RegisterAll()
    for _, hotel in pairs(Config.Hotels or {}) do
        local rooms = hotel.rooms or (Config.Rooms and Config.Rooms[hotel.id]) or {}

        for _, room in pairs(rooms) do
            if room.stash then
                Bridge.Stash.Register(hotel.id, room)
            end
        end
    end
end

CreateThread(function()
    Wait(2500)
    Bridge.Stash.RegisterAll()
end)

exports("StashType", function()
    return Bridge.Stash.Type
end)

exports("StashGetId", Bridge.Stash.GetId)
exports("StashRegister", Bridge.Stash.Register)
exports("StashOpen", Bridge.Stash.Open)
exports("StashRegisterAll", Bridge.Stash.RegisterAll)
