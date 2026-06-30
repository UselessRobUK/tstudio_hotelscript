local State = require "server.state"
local Rooms = require "configs.shared.rooms"

local function Main() return require "server.main" end

---@param hotelId string
---@param roomId number
---@param startTime number
---@param endTime number
---@return boolean
local function HasOverlap(hotelId, roomId, startTime, endTime)
    for _, booking in pairs(State.Bookings or {}) do
        if booking.hotel == hotelId
        and tonumber(booking.room) == tonumber(roomId)
        and booking.status ~= "cancelled"
        and startTime < tonumber(booking.end_time)
        and endTime > tonumber(booking.start_time) then
            return true
        end
    end
    return false
end

---@param src number
---@param data table
---@return boolean, string|table
local function CreateBooking(src, data)
    local identifier = Main().GetIdentifier(src)
    if not identifier then return false, "No identifier" end

    local hotelId   = data.hotelId
    local roomId    = tonumber(data.roomId)
    local startTime = tonumber(data.startTime) or os.time()
    local endTime   = tonumber(data.endTime) or (startTime + 86400)

    if endTime <= startTime then return false, "Invalid booking time" end

    local room = Main().GetRoom(hotelId, roomId)
    if not room then return false, "Invalid room" end

    if HasOverlap(hotelId, roomId, startTime, endTime) then return false, "Room already booked" end

    local hours        = math.ceil((endTime - startTime) / 3600)
    local pricePerHour = math.ceil((tonumber(room.price) or 0) / (tonumber(room.duration) or 24))
    local cost         = pricePerHour * hours

    if not exports[GetCurrentResourceName()]:RemoveMoney(src, cost, data.payment or "bank") then
        return false, "Not enough money"
    end

    local booking = {
        id         = #State.Bookings + 1,
        identifier = identifier,
        hotel      = hotelId,
        room       = roomId,
        start_time = startTime,
        end_time   = endTime,
        status     = "active",
        cost       = cost,
    }

    State.Bookings[#State.Bookings + 1] = booking

    local insertId = MySQL.insert.await(
        "INSERT INTO hotel_bookings (identifier, hotel, room, start_time, end_time, status, cost) VALUES (?, ?, ?, ?, ?, ?, ?)",
        { identifier, hotelId, roomId, startTime, endTime, booking.status, cost }
    )
    booking.id = insertId or booking.id

    State.Revenue[hotelId] = (State.Revenue[hotelId] or 0) + cost
    TriggerClientEvent("hotel:bookingCreated", src, roomId)
    return true, booking
end

---@param src number
---@param bookingId number
---@return boolean, string?
local function CancelBooking(src, bookingId)
    local identifier = Main().GetIdentifier(src)
    if not identifier then return false, "No identifier" end

    for _, booking in pairs(State.Bookings) do
        if tonumber(booking.id) == tonumber(bookingId)
        and booking.identifier == identifier
        and booking.status ~= "cancelled" then
            booking.status = "cancelled"
            MySQL.update.await("UPDATE hotel_bookings SET status = ? WHERE id = ?", { "cancelled", booking.id })
            TriggerClientEvent("hotel:bookingCancelled", src)
            return true
        end
    end
    return false, "Booking not found"
end

RegisterNetEvent("hotel:createBooking", function(data)
    local src = source
    if type(data) ~= "table" then return end
    local ok, result = CreateBooking(src, data)
    if not ok then TriggerClientEvent("hotel:bookingFailed", src, result or "Booking failed") end
end)

RegisterNetEvent("hotel:cancelBooking", function(bookingId)
    local src = source
    local ok, err = CancelBooking(src, bookingId)
    if not ok then Main().Notify(src, err or "Could not cancel booking.", "error") end
end)

lib.callback.register("hotel:getBookingRooms", function(_, hotelId)
    local hotel = Main().GetHotel(hotelId)
    return (hotel and hotel.rooms) or Rooms[hotelId] or {}
end)

CreateThread(function()
    Wait(2500)
    local rows = MySQL.query.await("SELECT * FROM hotel_bookings WHERE status = ?", { "active" })
    State.Bookings = rows or {}
end)

exports("CreateHotelBooking", CreateBooking)
exports("CancelHotelBooking", CancelBooking)

return { CreateBooking = CreateBooking, CancelBooking = CancelBooking }
