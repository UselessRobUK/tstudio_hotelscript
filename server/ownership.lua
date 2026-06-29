--========================================================--
-- Standalone Hotel Framework
-- server/ownership.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Ownership = Hotel.Ownership or {}

Hotel.Ownership.Hotels = Hotel.Ownership.Hotels or {}

local function Notify(src, msg, t)
    Hotel.Notify(src, msg, t or "inform")
end

function Hotel.Ownership.GetOwner(hotelId)
    return Hotel.Ownership.Hotels[hotelId]
        and Hotel.Ownership.Hotels[hotelId].owner
        or nil
end

function Hotel.Ownership.IsOwner(src, hotelId)
    local identifier = Hotel.GetIdentifier(src)
    if not identifier then return false end

    return Hotel.Ownership.GetOwner(hotelId) == identifier
end

function Hotel.Ownership.SetOwner(hotelId, identifier)
    Hotel.Ownership.Hotels[hotelId] = Hotel.Ownership.Hotels[hotelId] or {
        balance = 0,
        employees = {},
        reputation = 50
    }

    Hotel.Ownership.Hotels[hotelId].owner = identifier

    if MySQL then
        MySQL.insert.await([[
            INSERT INTO hotel_ownership
            (hotel, owner, balance, reputation)
            VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE owner = VALUES(owner)
        ]], {
            hotelId,
            identifier,
            Hotel.Ownership.Hotels[hotelId].balance or 0,
            Hotel.Ownership.Hotels[hotelId].reputation or 50
        })
    end

    return true
end

function Hotel.Ownership.AddBalance(hotelId, amount)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end

    Hotel.Ownership.Hotels[hotelId] = Hotel.Ownership.Hotels[hotelId] or {
        balance = 0,
        employees = {},
        reputation = 50
    }

    Hotel.Ownership.Hotels[hotelId].balance =
        (Hotel.Ownership.Hotels[hotelId].balance or 0) + amount

    if MySQL then
        MySQL.update.await(
            "UPDATE hotel_ownership SET balance = ? WHERE hotel = ?",
            { Hotel.Ownership.Hotels[hotelId].balance, hotelId }
        )
    end

    return true
end

function Hotel.Ownership.RemoveBalance(hotelId, amount)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end

    local hotel = Hotel.Ownership.Hotels[hotelId]
    if not hotel then return false end

    if (hotel.balance or 0) < amount then
        return false
    end

    hotel.balance = hotel.balance - amount

    if MySQL then
        MySQL.update.await(
            "UPDATE hotel_ownership SET balance = ? WHERE hotel = ?",
            { hotel.balance, hotelId }
        )
    end

    return true
end

function Hotel.Ownership.GetBalance(hotelId)
    return Hotel.Ownership.Hotels[hotelId]
        and Hotel.Ownership.Hotels[hotelId].balance
        or 0
end

RegisterNetEvent("hotel:setOwner", function(hotelId, targetIdentifier)
    local src = source

    if Hotel.IsAdmin and not Hotel.IsAdmin(src) then
        return Notify(src, "No permission.", "error")
    end

    if not hotelId or not targetIdentifier then
        return Notify(src, "Missing hotel or identifier.", "error")
    end

    Hotel.Ownership.SetOwner(hotelId, targetIdentifier)
    Notify(src, "Hotel owner updated.", "success")
end)

RegisterNetEvent("hotel:withdrawHotelFunds", function(hotelId, amount)
    local src = source
    amount = tonumber(amount) or 0

    if not Hotel.Ownership.IsOwner(src, hotelId) then
        return Notify(src, "No permission.", "error")
    end

    if not Hotel.Ownership.RemoveBalance(hotelId, amount) then
        return Notify(src, "Insufficient hotel balance.", "error")
    end

    exports[GetCurrentResourceName()]:AddMoney(src, amount, "bank", "hotel withdrawal")
    Notify(src, "Funds withdrawn.", "success")
end)

RegisterNetEvent("hotel:depositHotelFunds", function(hotelId, amount)
    local src = source
    amount = tonumber(amount) or 0

    if not Hotel.Ownership.IsOwner(src, hotelId) then
        return Notify(src, "No permission.", "error")
    end

    if not exports[GetCurrentResourceName()]:RemoveMoney(src, amount, "bank", "hotel deposit") then
        return Notify(src, "Not enough money.", "error")
    end

    Hotel.Ownership.AddBalance(hotelId, amount)
    Notify(src, "Funds deposited.", "success")
end)

CreateThread(function()
    Wait(2500)

    if not MySQL then return end

    local rows = MySQL.query.await("SELECT * FROM hotel_ownership", {})

    for _, row in pairs(rows or {}) do
        Hotel.Ownership.Hotels[row.hotel] = {
            owner = row.owner,
            balance = tonumber(row.balance) or 0,
            reputation = tonumber(row.reputation) or 50,
            employees = {}
        }
    end
end)

exports("SetHotelOwner", Hotel.Ownership.SetOwner)
exports("GetHotelOwner", Hotel.Ownership.GetOwner)
exports("IsHotelOwner", Hotel.Ownership.IsOwner)
exports("AddHotelBalance", Hotel.Ownership.AddBalance)
exports("RemoveHotelBalance", Hotel.Ownership.RemoveBalance)
exports("GetHotelBalance", Hotel.Ownership.GetBalance)
