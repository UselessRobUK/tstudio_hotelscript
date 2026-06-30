local Stash  = require "bridge.stash"
local Hotels = require "configs.shared.hotels"
local Rooms  = require "configs.shared.rooms"

local function Main() return require "server.main" end

lib.callback.register("hotel:requestStashAccess", function(src, hotelId, roomId)
    return exports[GetCurrentResourceName()]:HasRoomAccess(src, hotelId, tonumber(roomId))
end)

CreateThread(function()
    Wait(2000)
    Stash.RegisterAll(Hotels, Rooms)
end)

exports("GetHotelStashId",         Stash.GetId)
exports("RegisterHotelStash",      Stash.Register)
exports("RegisterAllHotelStashes", function() Stash.RegisterAll(Hotels, Rooms) end)
