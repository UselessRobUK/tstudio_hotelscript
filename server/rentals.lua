--========================================================--
-- Standalone Hotel Framework
-- server/rentals.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Rentals = Hotel.Rentals or {}

local function Notify(src, msg, t)
    Hotel.Notify(src, msg, t or "inform")
end

local function GetActiveRental(identifier)
    local rentals = Hotel.Rentals[identifier] or {}

    for _, rental in pairs(rentals) do
        if tonumber(rental.expires) > os.time() then
            return rental
        end
    end

    return nil
end

function Hotel.GetActiveRental(src)
    local identifier = Hotel.GetIdentifier(src)
    if not identifier then return nil end

    return GetActiveRental(identifier)
end

function Hotel.CreateRental(src, hotelId, roomId, payment)
    local identifier = Hotel.GetIdentifier(src)
    if not identifier then return false, "No identifier" end

    local room = Hotel.GetRoom(hotelId, roomId)
    if not room then return false, "Invalid room" end

    if GetActiveRental(identifier) then
        return false, "You already have an active room"
    end

    local price = tonumber(room.price) or 0

    if not exports[GetCurrentResourceName()]:RemoveMoney(src, price, payment or "cash") then
        return false, "Not enough money"
    end

    local expires = os.time() + ((tonumber(room.duration) or 24) * 3600)

    local rental = {
        identifier = identifier,
        hotel = hotelId,
        room = tonumber(roomId),
        expires = expires,
        price = price
    }

    Hotel.Rentals[identifier] = Hotel.Rentals[identifier] or {}
    Hotel.Rentals[identifier][#Hotel.Rentals[identifier] + 1] = rental

    if MySQL then
        MySQL.insert.await(
            "INSERT INTO hotel_rentals (identifier, hotel, room, expires) VALUES (?, ?, ?, ?)",
            { identifier, hotelId, tonumber(roomId), expires }
        )
    end

    Hotel.Revenue[hotelId] = (Hotel.Revenue[hotelId] or 0) + price

    TriggerClientEvent("hotel:receiveKey", src, {
        hotel = hotelId,
        room = tonumber(roomId),
        expires = expires
    })

    TriggerClientEvent("hotel:anim:receiveKey", src)
    Notify(src, "Room rented successfully.", "success")

    return true, rental
end

function Hotel.CancelRental(src, hotelId, roomId)
    local identifier = Hotel.GetIdentifier(src)
    if not identifier then return false end

    local rentals = Hotel.Rentals[identifier] or {}

    for i = #rentals, 1, -1 do
        local rental = rentals[i]

        if rental.hotel == hotelId and tonumber(rental.room) == tonumber(roomId) then
            table.remove(rentals, i)

            if MySQL then
                MySQL.query.await(
                    "DELETE FROM hotel_rentals WHERE identifier = ? AND hotel = ? AND room = ?",
                    { identifier, hotelId, tonumber(roomId) }
                )
            end

            TriggerClientEvent("hotel:removeKey", src, hotelId, tonumber(roomId))
            Notify(src, "Rental cancelled.", "success")

            return true
        end
    end

    return false
end

function Hotel.ExtendRental(src, hotelId, roomId, hours, payment)
    local identifier = Hotel.GetIdentifier(src)
    if not identifier then return false, "No identifier" end

    hours = tonumber(hours) or 0
    if hours <= 0 then return false, "Invalid duration" end

    local room = Hotel.GetRoom(hotelId, roomId)
    if not room then return false, "Invalid room" end

    local pricePerHour = math.ceil((tonumber(room.price) or 0) / (tonumber(room.duration) or 24))
    local cost = pricePerHour * hours

    if not exports[GetCurrentResourceName()]:RemoveMoney(src, cost, payment or "cash") then
        return false, "Not enough money"
    end

    local rentals = Hotel.Rentals[identifier] or {}

    for _, rental in pairs(rentals) do
        if rental.hotel == hotelId and tonumber(rental.room) == tonumber(roomId) then
            rental.expires = tonumber(rental.expires) + (hours * 3600)

            if MySQL then
                MySQL.update.await(
                    "UPDATE hotel_rentals SET expires = ? WHERE identifier = ? AND hotel = ? AND room = ?",
                    { rental.expires, identifier, hotelId, tonumber(roomId) }
                )
            end

            Hotel.Revenue[hotelId] = (Hotel.Revenue[hotelId] or 0) + cost

            TriggerClientEvent("hotel:receiveKey", src, {
                hotel = hotelId,
                room = tonumber(roomId),
                expires = rental.expires
            })

            Notify(src, "Rental extended.", "success")
            return true, rental
        end
    end

    return false, "Rental not found"
end

RegisterNetEvent("hotel:rentRoom", function(data)
    local src = source
    if type(data) ~= "table" then return end

    local ok, result = Hotel.CreateRental(
        src,
        data.hotelId,
        tonumber(data.roomId),
        data.payment or Config.DefaultPayment or "cash"
    )

    if not ok then
        Notify(src, result or "Rental failed.", "error")
    end
end)

RegisterNetEvent("hotel:cancelRental", function(hotelId, roomId)
    local src = source

    if not Hotel.CancelRental(src, hotelId, tonumber(roomId)) then
        Notify(src, "Could not cancel rental.", "error")
    end
end)

RegisterNetEvent("hotel:extendRental", function(hotelId, roomId, hours, payment)
    local src = source

    local ok, err = Hotel.ExtendRental(
        src,
        hotelId,
        tonumber(roomId),
        tonumber(hours),
        payment or Config.DefaultPayment or "cash"
    )

    if not ok then
        Notify(src, err or "Could not extend rental.", "error")
    end
end)

RegisterNetEvent("hotel:syncRental", function()
    local src = source
    local identifier = Hotel.GetIdentifier(src)

    if not identifier then return end

    TriggerClientEvent("hotel:syncKeys", src, Hotel.Rentals[identifier] or {})
end)

exports("CreateHotelRental", Hotel.CreateRental)
exports("CancelHotelRental
