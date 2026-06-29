--========================================================--
-- Standalone Hotel Framework
-- server/bookings.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Bookings = Hotel.Bookings or {}

local function Notify(src, msg, t)
    Hotel.Notify(src, msg, t or "inform")
end

local function HasOverlap(hotelId, roomId, startTime, endTime)
    for _, booking in pairs(Hotel.Bookings or {}) do
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

function Hotel.CreateBooking(src, data)
    local identifier = Hotel.GetIdentifier(src)
    if not identifier then return false, "No identifier" end

    local hotelId = data.hotelId
    local roomId = tonumber(data.roomId)
    local startTime = tonumber(data.startTime) or os.time()
    local endTime = tonumber(data.endTime) or (startTime + 86400)

    if endTime <= startTime then
        return false, "Invalid booking time"
    end

    local room = Hotel.GetRoom(hotelId, roomId)
    if not room then return false, "Invalid room" end

    if HasOverlap(hotelId, roomId, startTime, endTime) then
        return false, "Room already booked"
    end

    local hours = math.ceil((endTime - startTime) / 3600)
    local pricePerHour = math.ceil((tonumber(room.price) or 0) / (tonumber(room.duration) or 24))
    local cost = pricePerHour * hours

    if not exports[GetCurrentResourceName()]:RemoveMoney(src, cost, data.payment or "bank") then
        return false, "Not enough money"
    end

    local booking = {
        id = #Hotel.Bookings + 1,
        identifier = identifier,
        hotel = hotelId,
        room = roomId,
        start_time = startTime,
        end_time = endTime,
        status = "active",
        cost = cost
    }

    Hotel.Bookings[#Hotel.Bookings + 1] = booking

    if MySQL then
        local insertId = MySQL.insert.await([[
            INSERT INTO hotel_bookings
            (identifier, hotel, room, start_time, end_time, status, cost)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], {
            identifier,
            hotelId,
            roomId,
            startTime,
            endTime,
            booking.status,
            cost
        })

        booking.id = insertId or booking.id
    end

    Hotel.Revenue[hotelId] = (Hotel.Revenue[hotelId] or 0) + cost

    TriggerClientEvent("hotel:bookingCreated", src, roomId)
    return true, booking
end

function Hotel.CancelBooking(src, bookingId)
    local identifier = Hotel.GetIdentifier(src)
    if not identifier then return false, "No identifier" end

    for _, booking in pairs(Hotel.Bookings) do
        if tonumber(booking.id) == tonumber(bookingId)
        and booking.identifier == identifier
        and booking.status ~= "cancelled" then
            booking.status = "cancelled"

            if MySQL then
                MySQL.update.await(
                    "UPDATE hotel_bookings SET status = ? WHERE id = ?",
                    { "cancelled", booking.id }
                )
            end

            TriggerClientEvent("hotel:bookingCancelled", src)
            return true
        end
    end

    return false, "Booking not found"
end

function Hotel.ExtendBooking(src, bookingId, hours, payment)
    local identifier = Hotel.GetIdentifier(src)
    if not identifier then return false, "No identifier" end

    hours = tonumber(hours) or 0
    if hours <= 0 then return false, "Invalid hours" end

    for _, booking in pairs(Hotel.Bookings) do
        if tonumber(booking.id) == tonumber(bookingId)
        and booking.identifier == identifier
        and booking.status == "active" then

            local room = Hotel.GetRoom(booking.hotel, booking.room)
            if not room then return false, "Invalid room" end

            local newEnd = tonumber(booking.end_time) + (hours * 3600)

            if HasOverlap(booking.hotel, booking.room, tonumber(booking.end_time), newEnd) then
                return false, "Room is already booked after your stay"
            end

            local pricePerHour = math.ceil((tonumber(room.price) or 0) / (tonumber(room.duration) or 24))
            local cost = pricePerHour * hours

            if not exports[GetCurrentResourceName()]:RemoveMoney(src, cost, payment or "bank") then
                return false, "Not enough money"
            end

            booking.end_time = newEnd
            booking.cost = tonumber(booking.cost or 0) + cost

            if MySQL then
                MySQL.update.await(
                    "UPDATE hotel_bookings SET end_time = ?, cost = ? WHERE id = ?",
                    { booking.end_time, booking.cost, booking.id }
                )
            end

            Hotel.Revenue[booking.hotel] = (Hotel.Revenue[booking.hotel] or 0) + cost

            TriggerClientEvent("hotel:bookingExtended", src)
            return true, booking
        end
    end

    return false, "Booking not found"
end

RegisterNetEvent("hotel:createBooking", function(data)
    local src = source
    if type(data) ~= "table" then return end

    local ok, result = Hotel.CreateBooking(src, data)

    if not ok then
        TriggerClientEvent("hotel:bookingFailed", src, result or "Booking failed")
    end
end)

RegisterNetEvent("hotel:cancelBooking", function(bookingId)
    local src = source
    local ok, err = Hotel.CancelBooking(src, bookingId)

    if not ok then
        Notify(src, err or "Could not cancel booking.", "error")
    end
end)

RegisterNetEvent("hotel:extendBooking", function(bookingId, hours, payment)
    local src = source
    local ok, err = Hotel.ExtendBooking(src, bookingId, hours, payment)

    if not ok then
        Notify(src, err or "Could not extend booking.", "error")
    end
end)

RegisterNetEvent("hotel:getBookingRooms", function(hotelId)
    local src = source
    local rooms = {}

    local hotel = Hotel.GetHotel(hotelId)
    if hotel and hotel.rooms then
        rooms = hotel.rooms
    elseif Config.Rooms and Config.Rooms[hotelId] then
        rooms = Config.Rooms[hotelId]
    end

    TriggerClientEvent("hotel:receiveBookingRooms", src, hotelId, rooms)
end)

CreateThread(function()
    Wait(2500)

    if not MySQL then return end

    local rows = MySQL.query.await(
        "SELECT * FROM hotel_bookings WHERE status = ?",
        { "active" }
    )

    Hotel.Bookings = rows or {}
end)

exports("CreateHotelBooking", Hotel.CreateBooking)
exports("CancelHotelBooking", Hotel.CancelBooking)
exports("ExtendHotelBooking", Hotel.Extend
