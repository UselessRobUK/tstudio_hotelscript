local Config = require "configs.shared.main"
local State  = require "server.state"
local Rooms  = require "configs.shared.rooms"

local function Main()      return require "server.main" end
local function Ownership() return require "server.ownership" end

---@param src number
---@param hotelId? string
---@return boolean
local function IsBoss(src, hotelId)
    local identifier = Main().GetIdentifier(src)
    if not identifier then return false end
    if Config.BossIdentifiers[identifier] then return true end
    return Ownership().IsOwner(src, hotelId)
end

---@param hotelId string
---@return table
local function GetDashboard(hotelId)
    local activeRooms = 0
    local tenants     = {}
    for identifier, rentals in pairs(State.Rentals or {}) do
        for _, rental in pairs(rentals) do
            if rental.hotel == hotelId and tonumber(rental.expires) > os.time() then
                activeRooms = activeRooms + 1
                tenants[#tenants + 1] = { identifier = identifier, room = rental.room, expires = rental.expires }
            end
        end
    end
    return {
        hotel       = hotelId,
        activeRooms = activeRooms,
        tenants     = tenants,
        revenue     = State.Revenue[hotelId] or 0,
        complaints  = State.Complaints[hotelId] or {},
    }
end

lib.callback.register("hotel:getDashboard", function(src, hotelId)
    if not IsBoss(src, hotelId) then return nil end
    return GetDashboard(hotelId)
end)

lib.callback.register("hotel:getBossRooms", function(src, hotelId)
    if not IsBoss(src, hotelId) then return nil end
    local hotel = Main().GetHotel(hotelId)
    return (hotel and hotel.rooms) or Rooms[hotelId] or {}
end)

lib.callback.register("hotel:getTenants", function(src, hotelId)
    if not IsBoss(src, hotelId) then return nil end
    local tenants = {}
    for identifier, rentals in pairs(State.Rentals or {}) do
        for _, rental in pairs(rentals) do
            if rental.hotel == hotelId and tonumber(rental.expires) > os.time() then
                tenants[#tenants + 1] = { identifier = identifier, hotel = rental.hotel, room = rental.room, expires = rental.expires }
            end
        end
    end
    return tenants
end)

RegisterNetEvent("hotel:changePrice", function(hotelId, roomId, price)
    local src = source
    if not IsBoss(src, hotelId) then return Main().Notify(src, "No permission.", "error") end
    price  = tonumber(price)
    roomId = tonumber(roomId)
    if not price or price < 0 then return Main().Notify(src, "Invalid price.", "error") end
    local room = Main().GetRoom(hotelId, roomId)
    if not room then return Main().Notify(src, "Room not found.", "error") end
    room.price = price
    Main().Notify(src, "Room price updated.", "success")
    TriggerClientEvent("hotel:uiRefreshRooms", -1)
end)

RegisterNetEvent("hotel:evictPlayer", function(hotelId, targetIdentifier)
    local src = source
    if not IsBoss(src, hotelId) then return Main().Notify(src, "No permission.", "error") end
    if not targetIdentifier then return Main().Notify(src, "Missing tenant identifier.", "error") end
    local rentals = State.Rentals[targetIdentifier]
    if rentals then
        for i = #rentals, 1, -1 do
            if rentals[i].hotel == hotelId then table.remove(rentals, i) end
        end
    end
    MySQL.query.await("DELETE FROM hotel_rentals WHERE identifier = ? AND hotel = ?", { targetIdentifier, hotelId })
    Main().Notify(src, "Tenant evicted.", "success")
end)

RegisterNetEvent("hotel:issueFine", function(hotelId, targetIdentifier, amount, reason)
    local src = source
    if not IsBoss(src, hotelId) then return Main().Notify(src, "No permission.", "error") end
    amount = tonumber(amount) or 0
    if amount <= 0 then return Main().Notify(src, "Invalid fine amount.", "error") end
    MySQL.insert.await(
        "INSERT INTO hotel_fines (hotel, identifier, amount, reason, created_at) VALUES (?, ?, ?, ?, ?)",
        { hotelId, targetIdentifier, amount, reason or "Hotel fine", os.time() }
    )
    Main().Notify(src, "Fine issued.", "success")
end)

RegisterNetEvent("hotel:refundPlayer", function(hotelId, targetIdentifier, amount, reason)
    local src = source
    if not IsBoss(src, hotelId) then return Main().Notify(src, "No permission.", "error") end
    amount = tonumber(amount) or 0
    if amount <= 0 then return Main().Notify(src, "Invalid refund amount.", "error") end
    State.Revenue[hotelId] = math.max(0, (State.Revenue[hotelId] or 0) - amount)
    MySQL.insert.await(
        "INSERT INTO hotel_transactions (identifier, amount, type, reason, created_at) VALUES (?, ?, ?, ?, ?)",
        { targetIdentifier, amount, "refund", reason or "Hotel refund", os.time() }
    )
    Main().Notify(src, "Refund recorded.", "success")
end)

exports("IsHotelBoss",       IsBoss)
exports("GetHotelDashboard", GetDashboard)

return { IsBoss = IsBoss, GetDashboard = GetDashboard }
