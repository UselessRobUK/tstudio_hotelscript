--========================================================--
-- Standalone Hotel Framework
-- server/boss.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Boss = {}

local BossIdentifiers = Config.BossIdentifiers or {
    -- ["license:xxxxxxxxxxxxxxxx"] = true
}

local function Notify(src, msg, t)
    Hotel.Notify(src, msg, t or "inform")
end

function Hotel.IsBoss(src, hotelId)
    local identifier = Hotel.GetIdentifier(src)
    if not identifier then return false end

    if BossIdentifiers[identifier] then
        return true
    end

    if Hotel.Ownership and Hotel.Ownership.IsOwner then
        return Hotel.Ownership.IsOwner(src, hotelId)
    end

    return false
end

function Hotel.Boss.GetDashboard(hotelId)
    local activeRooms = 0
    local tenants = {}

    for identifier, rentals in pairs(Hotel.Rentals or {}) do
        for _, rental in pairs(rentals) do
            if rental.hotel == hotelId and tonumber(rental.expires) > os.time() then
                activeRooms = activeRooms + 1

                tenants[#tenants + 1] = {
                    identifier = identifier,
                    room = rental.room,
                    expires = rental.expires
                }
            end
        end
    end

    return {
        hotel = hotelId,
        activeRooms = activeRooms,
        tenants = tenants,
        revenue = Hotel.Revenue[hotelId] or 0,
        complaints = Hotel.Complaints[hotelId] or {}
    }
end

RegisterNetEvent("hotel:getDashboard", function(hotelId)
    local src = source

    if not Hotel.IsBoss(src, hotelId) then
        return Notify(src, "No permission.", "error")
    end

    TriggerClientEvent(
        "hotel:receiveDashboard",
        src,
        hotelId,
        Hotel.Boss.GetDashboard(hotelId)
    )
end)

RegisterNetEvent("hotel:getBossRooms", function(hotelId)
    local src = source

    if not Hotel.IsBoss(src, hotelId) then
        return Notify(src, "No permission.", "error")
    end

    local hotel = Hotel.GetHotel(hotelId)
    local rooms = hotel and hotel.rooms or Config.Rooms and Config.Rooms[hotelId] or {}

    TriggerClientEvent("hotel:receiveBossRooms", src, hotelId, rooms)
end)

RegisterNetEvent("hotel:getTenants", function(hotelId)
    local src = source

    if not Hotel.IsBoss(src, hotelId) then
        return Notify(src, "No permission.", "error")
    end

    local tenants = {}

    for identifier, rentals in pairs(Hotel.Rentals or {}) do
        for _, rental in pairs(rentals) do
            if rental.hotel == hotelId and tonumber(rental.expires) > os.time() then
                tenants[#tenants + 1] = {
                    identifier = identifier,
                    hotel = rental.hotel,
                    room = rental.room,
                    expires = rental.expires
                }
            end
        end
    end

    TriggerClientEvent("hotel:receiveTenants", src, hotelId, tenants)
end)

RegisterNetEvent("hotel:changePrice", function(hotelId, roomId, price)
    local src = source

    if not Hotel.IsBoss(src, hotelId) then
        return Notify(src, "No permission.", "error")
    end

    price = tonumber(price)
    roomId = tonumber(roomId)

    if not price or price < 0 then
        return Notify(src, "Invalid price.", "error")
    end

    local room = Hotel.GetRoom(hotelId, roomId)
    if not room then
        return Notify(src, "Room not found.", "error")
    end

    room.price = price

    Notify(src, "Room price updated.", "success")

    TriggerClientEvent("hotel:uiRefreshRooms", -1)
end)

RegisterNetEvent("hotel:evictPlayer", function(hotelId, targetIdentifier)
    local src = source

    if not Hotel.IsBoss(src, hotelId) then
        return Notify(src, "No permission.", "error")
    end

    if not targetIdentifier then
        return Notify(src, "Missing tenant identifier.", "error")
    end

    local rentals = Hotel.Rentals[targetIdentifier]

    if rentals then
        for i = #rentals, 1, -1 do
            if rentals[i].hotel == hotelId then
                table.remove(rentals, i)
            end
        end
    end

    if MySQL then
        MySQL.query.await(
            "DELETE FROM hotel_rentals WHERE identifier = ? AND hotel = ?",
            { targetIdentifier, hotelId }
        )
    end

    Notify(src, "Tenant evicted.", "success")
end)

RegisterNetEvent("hotel:issueFine", function(hotelId, targetIdentifier, amount, reason)
    local src = source

    if not Hotel.IsBoss(src, hotelId) then
        return Notify(src, "No permission.", "error")
    end

    amount = tonumber(amount) or 0
    if amount <= 0 then
        return Notify(src, "Invalid fine amount.", "error")
    end

    if MySQL then
        MySQL.insert.await([[
            INSERT INTO hotel_fines
            (hotel, identifier, amount, reason, created_at)
            VALUES (?, ?, ?, ?, ?)
        ]], {
            hotelId,
            targetIdentifier,
            amount,
            reason or "Hotel fine",
            os.time()
        })
    end

    Notify(src, "Fine issued.", "success")
end)

RegisterNetEvent("hotel:refundPlayer", function(hotelId, targetIdentifier, amount, reason)
    local src = source

    if not Hotel.IsBoss(src, hotelId) then
        return Notify(src, "No permission.", "error")
    end

    amount = tonumber(amount) or 0
    if amount <= 0 then
        return Notify(src, "Invalid refund amount.", "error")
    end

    Hotel.Revenue[hotelId] = math.max(0, (Hotel.Revenue[hotelId] or 0) - amount)

    if MySQL then
        MySQL.insert.await([[
            INSERT INTO hotel_transactions
            (identifier, amount, type, reason, created_at)
            VALUES (?, ?, ?, ?, ?)
        ]], {
            targetIdentifier,
            amount,
            "refund",
            reason or "Hotel refund",
            os.time()
        })
    end

    Notify(src, "Refund recorded.", "success")
end)

exports("IsHotelBoss", Hotel.IsBoss)
exports("GetHotelDashboard", Hotel.Boss.GetDashboard)
