local State = require "server.state"
local Rooms = require "configs.shared.rooms"

local function Main() return require "server.main" end

---@param hotelId string
---@return table
local function GetAll(hotelId)
    local hotel = Main().GetHotel(hotelId)
    if hotel and hotel.rooms then return hotel.rooms end
    return Rooms[hotelId] or {}
end

---@param hotelId string
---@param roomId number
---@return boolean
local function IsAvailable(hotelId, roomId)
    local now = os.time()
    for _, rentals in pairs(State.Rentals or {}) do
        for _, rental in pairs(rentals) do
            if rental.hotel == hotelId
            and tonumber(rental.room) == tonumber(roomId)
            and tonumber(rental.expires) > now then
                return false
            end
        end
    end
    return true
end

---@param hotelId string
---@param roomId number
---@param price number
---@return boolean
local function SetPrice(hotelId, roomId, price)
    local room = Main().GetRoom(hotelId, tonumber(roomId))
    if not room then return false end
    room.price = tonumber(price) or room.price
    return true
end

lib.callback.register("hotel:getRoomAvailability", function(_, hotelId)
    local list = {}
    for _, room in pairs(GetAll(hotelId)) do
        list[#list + 1] = {
            id        = room.id,
            label     = room.label,
            price     = room.price,
            duration  = room.duration,
            available = IsAvailable(hotelId, room.id),
            state     = State.RoomStates[hotelId .. "_" .. room.id] or "clean",
        }
    end
    return list
end)

exports("GetHotelRoom",          function(hotelId, roomId) return Main().GetRoom(hotelId, roomId) end)
exports("GetHotelRooms",         GetAll)
exports("IsHotelRoomAvailable",  IsAvailable)
exports("SetHotelRoomPrice",     SetPrice)

return { GetAll = GetAll, IsAvailable = IsAvailable, SetPrice = SetPrice }
