--========================================================--
-- Standalone Hotel Framework
-- server/rooms.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Rooms = Hotel.Rooms or {}

function Hotel.Rooms.Get(hotelId, roomId)
    return Hotel.GetRoom(hotelId, tonumber(roomId))
end

function Hotel.Rooms.GetAll(hotelId)
    local hotel = Hotel.GetHotel(hotelId)

    if hotel and hotel.rooms then
        return hotel.rooms
    end

    if Config.Rooms and Config.Rooms[hotelId] then
        return Config.Rooms[hotelId]
    end

    return {}
end

function Hotel.Rooms.IsAvailable(hotelId, roomId)
    local now = os.time()

    for _, rentals in pairs(Hotel.Rentals or {}) do
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

function Hotel.Rooms.SetPrice(hotelId, roomId, price)
    local room = Hotel.GetRoom(hotelId, tonumber(roomId))
    if not room then return false end

    room.price = tonumber(price) or room.price
    return true
end

RegisterNetEvent("hotel:getRoomAvailability", function(hotelId)
    local src = source
    local rooms = {}

    for _, room in pairs(Hotel.Rooms.GetAll(hotelId)) do
        rooms[#rooms + 1] = {
            id = room.id,
            label = room.label,
            price = room.price,
            duration = room.duration,
            available = Hotel.Rooms.IsAvailable(hotelId, room.id),
            state = Hotel.GetRoomState and Hotel.GetRoomState(hotelId, room.id) or "clean"
        }
    end

    TriggerClientEvent("hotel:receiveRoomAvailability", src, hotelId, rooms)
end)

exports("GetHotelRoom", Hotel.Rooms.Get)
exports("GetHotelRooms", Hotel.Rooms.GetAll)
exports("IsHotelRoomAvailable", Hotel.Rooms.IsAvailable)
exports("SetHotelRoomPrice", Hotel.Rooms.SetPrice)
