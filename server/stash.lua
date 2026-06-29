local Stash  = require "bridge.stash"
local Hotels = require "configs.shared.hotels"
local Rooms  = require "configs.shared.rooms"

local function Main() return require "server.main" end

RegisterNetEvent("hotel:requestStashAccess", function(hotelId, roomId)
    local src = source
    if not exports[GetCurrentResourceName()]:HasRoomAccess(src, hotelId, tonumber(roomId)) then
        return Main().Notify(src, "You don't have access to this stash.", "error")
    end
    TriggerClientEvent("hotel:stashApproved", src, hotelId, tonumber(roomId))
end)

CreateThread(function()
    Wait(2000)
    Stash.RegisterAll(Hotels, Rooms)
end)

exports("GetHotelStashId",         Stash.GetId)
exports("RegisterHotelStash",      Stash.Register)
exports("RegisterAllHotelStashes", function() Stash.RegisterAll(Hotels, Rooms) end)
