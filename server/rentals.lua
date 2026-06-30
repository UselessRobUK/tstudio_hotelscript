local Config  = require "configs.shared.main"
local State   = require "server.state"
local Banking = require "bridge.banking"

local function Main() return require "server.main" end
local function Keys() return require "server.keys" end

---@param identifier string
---@return table|nil
local function GetActiveRental(identifier)
    for _, rental in pairs(State.Rentals[identifier] or {}) do
        if tonumber(rental.expires) > os.time() then return rental end
    end
    return nil
end

---@param src number
---@return table|nil
local function GetActiveRentalForPlayer(src)
    local identifier = Main().GetIdentifier(src)
    if not identifier then return nil end
    return GetActiveRental(identifier)
end

---@param src number
---@param hotelId string
---@param roomId number
---@param payment? string
---@return boolean, string|table
local function CreateRental(src, hotelId, roomId, payment)
    local identifier = Main().GetIdentifier(src)
    if not identifier then return false, "No identifier" end

    local room = Main().GetRoom(hotelId, roomId)
    if not room then return false, "Invalid room" end

    if GetActiveRental(identifier) then return false, "You already have an active room" end

    local price = tonumber(room.price) or 0
    if not Banking.Remove(src, price, payment or "cash") then
        return false, "Not enough money"
    end

    local expires = os.time() + ((tonumber(room.duration) or 24) * 3600)
    local rental  = { identifier = identifier, hotel = hotelId, room = tonumber(roomId), expires = expires, price = price }

    State.Rentals[identifier] = State.Rentals[identifier] or {}
    State.Rentals[identifier][#State.Rentals[identifier] + 1] = rental

    MySQL.insert.await(
        "INSERT INTO hotel_rentals (identifier, hotel, room, expires) VALUES (?, ?, ?, ?)",
        { identifier, hotelId, tonumber(roomId), expires }
    )

    State.Revenue[hotelId] = (State.Revenue[hotelId] or 0) + price

    Keys().Give(src, hotelId, tonumber(roomId), expires)
    TriggerClientEvent("hotel:anim:receiveKey", src)
    Main().Notify(src, "Room rented successfully.", "success")
    return true, rental
end

---@param src number
---@param hotelId string
---@param roomId number
---@return boolean
local function CancelRental(src, hotelId, roomId)
    local identifier = Main().GetIdentifier(src)
    if not identifier then return false end

    local rentals = State.Rentals[identifier] or {}
    for i = #rentals, 1, -1 do
        if rentals[i].hotel == hotelId and tonumber(rentals[i].room) == tonumber(roomId) then
            table.remove(rentals, i)
            MySQL.query.await(
                "DELETE FROM hotel_rentals WHERE identifier = ? AND hotel = ? AND room = ?",
                { identifier, hotelId, tonumber(roomId) }
            )
            Keys().Remove(src, hotelId, tonumber(roomId))
            Main().Notify(src, "Rental cancelled.", "success")
            return true
        end
    end
    return false
end

---@param src number
---@param hotelId string
---@param roomId number
---@param hours number
---@param payment? string
---@return boolean, string|table
local function ExtendRental(src, hotelId, roomId, hours, payment)
    local identifier = Main().GetIdentifier(src)
    if not identifier then return false, "No identifier" end

    hours = tonumber(hours) or 0
    if hours <= 0 then return false, "Invalid duration" end

    local room = Main().GetRoom(hotelId, roomId)
    if not room then return false, "Invalid room" end

    local pricePerHour = math.ceil((tonumber(room.price) or 0) / (tonumber(room.duration) or 24))
    local cost = pricePerHour * hours

    if not Banking.Remove(src, cost, payment or "cash") then
        return false, "Not enough money"
    end

    for _, rental in pairs(State.Rentals[identifier] or {}) do
        if rental.hotel == hotelId and tonumber(rental.room) == tonumber(roomId) then
            rental.expires = tonumber(rental.expires) + (hours * 3600)
            MySQL.update.await(
                "UPDATE hotel_rentals SET expires = ? WHERE identifier = ? AND hotel = ? AND room = ?",
                { rental.expires, identifier, hotelId, tonumber(roomId) }
            )
            State.Revenue[hotelId] = (State.Revenue[hotelId] or 0) + cost
            Keys().Give(src, hotelId, tonumber(roomId), rental.expires)
            Main().Notify(src, "Rental extended.", "success")
            return true, rental
        end
    end

    return false, "Rental not found"
end

RegisterNetEvent("hotel:rentRoom", function(data)
    local src = source
    if type(data) ~= "table" then return end
    local ok, result = CreateRental(src, data.hotelId, tonumber(data.roomId), data.payment or Config.DefaultPayment or "cash")
    if not ok then Main().Notify(src, result or "Rental failed.", "error") end
end)

RegisterNetEvent("hotel:cancelRental", function(hotelId, roomId)
    local src = source
    if not CancelRental(src, hotelId, tonumber(roomId)) then
        Main().Notify(src, "Could not cancel rental.", "error")
    end
end)

RegisterNetEvent("hotel:extendRental", function(hotelId, roomId, hours, payment)
    local src = source
    local ok, err = ExtendRental(src, hotelId, tonumber(roomId), tonumber(hours), payment or Config.DefaultPayment or "cash")
    if not ok then Main().Notify(src, err or "Could not extend rental.", "error") end
end)

RegisterNetEvent("hotel:syncRental", function()
    local src        = source
    local identifier = Main().GetIdentifier(src)
    if not identifier then return end
    TriggerClientEvent("hotel:syncKeys", src, State.Rentals[identifier] or {})
end)

exports("CreateHotelRental",       CreateRental)
exports("CancelHotelRental",       CancelRental)
exports("ExtendHotelRental",       ExtendRental)
exports("GetActiveHotelRental",    GetActiveRentalForPlayer)

return { CreateRental = CreateRental, CancelRental = CancelRental, ExtendRental = ExtendRental, GetActiveRental = GetActiveRentalForPlayer }
