-- Superseded by bridge/doorlock and bridge/stash — kept for reference.
-- Not loaded by server/_index.lua.
local Doorlock = require "bridge.doorlock"
local Stash    = require "bridge.stash"
local Hotels   = require "configs.shared.hotels"

local function RegisterRoom(hotelId, room)
    Doorlock.Register(hotelId, room)
    Stash.Register(hotelId, room)
end

local function RegisterHotel(hotel)
    if not hotel.rooms then return end
    for _, room in pairs(hotel.rooms) do
        RegisterRoom(hotel.id, room)
    end
end

exports("RegisterHotelBindings", RegisterHotel)
exports("RegisterRoomBindings",  RegisterRoom)

return { RegisterRoom = RegisterRoom, RegisterHotel = RegisterHotel }
