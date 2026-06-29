local State = require "server.state"

local Keys = {}

local function Main() return require "server.main" end

---@param identifier string
---@return table
local function Get(identifier)
    return Keys[identifier] or {}
end

---@param identifier string
---@param hotelId string
---@param roomId number
---@return boolean
local function Has(identifier, hotelId, roomId)
    local now = os.time()
    for _, key in pairs(Get(identifier)) do
        if key.hotel == hotelId
        and tonumber(key.room) == tonumber(roomId)
        and (not key.expires or tonumber(key.expires) > now) then
            return true
        end
    end
    return false
end

---@param src number
---@param hotelId string
---@param roomId number
---@param expires number
---@return boolean
local function Give(src, hotelId, roomId, expires)
    local identifier = Main().GetIdentifier(src)
    if not identifier then return false end

    Keys[identifier] = Keys[identifier] or {}

    for _, key in pairs(Keys[identifier]) do
        if key.hotel == hotelId and tonumber(key.room) == tonumber(roomId) then
            key.expires = expires
            TriggerClientEvent("hotel:receiveKey", src, key)
            return true
        end
    end

    local key = { hotel = hotelId, room = tonumber(roomId), expires = expires }
    Keys[identifier][#Keys[identifier] + 1] = key

    MySQL.insert.await(
        "INSERT INTO hotel_keys (identifier, hotel, room, expires) VALUES (?, ?, ?, ?)",
        { identifier, hotelId, roomId, expires }
    )

    TriggerClientEvent("hotel:receiveKey", src, key)
    return true
end

---@param src number
---@param hotelId string
---@param roomId number
---@return boolean
local function Remove(src, hotelId, roomId)
    local identifier = Main().GetIdentifier(src)
    if not identifier then return false end

    local list = Keys[identifier] or {}
    for i = #list, 1, -1 do
        if list[i].hotel == hotelId and tonumber(list[i].room) == tonumber(roomId) then
            table.remove(list, i)
            MySQL.query.await(
                "DELETE FROM hotel_keys WHERE identifier = ? AND hotel = ? AND room = ?",
                { identifier, hotelId, tonumber(roomId) }
            )
            TriggerClientEvent("hotel:removeKey", src, hotelId, tonumber(roomId))
            return true
        end
    end
    return false
end

RegisterNetEvent("hotel:syncKeys", function()
    local src        = source
    local identifier = Main().GetIdentifier(src)
    if not identifier then return end
    TriggerClientEvent("hotel:syncKeys", src, Get(identifier))
end)

RegisterNetEvent("hotel:requestRoomEntry", function(hotelId, roomId)
    local src        = source
    local identifier = Main().GetIdentifier(src)
    if not identifier then return end

    if not Has(identifier, hotelId, tonumber(roomId)) then
        return Main().Notify(src, "You don't own this room key.", "error")
    end

    TriggerClientEvent("hotel:roomAccessApproved", src, hotelId, tonumber(roomId))
    TriggerClientEvent("hotel:requestEnterInstance", src, hotelId, tonumber(roomId))
end)

RegisterNetEvent("hotel:duplicateKey", function(hotelId, roomId)
    local src    = source
    local rental = exports[GetCurrentResourceName()]:GetActiveHotelRental(src)

    if not rental then return Main().Notify(src, "No active rental.", "error") end
    if rental.hotel ~= hotelId or tonumber(rental.room) ~= tonumber(roomId) then
        return Main().Notify(src, "You don't own this room.", "error")
    end

    Give(src, hotelId, tonumber(roomId), rental.expires)
    Main().Notify(src, "Duplicate key issued.", "success")
end)

CreateThread(function()
    Wait(2500)
    local rows = MySQL.query.await("SELECT * FROM hotel_keys", {})
    for _, row in pairs(rows or {}) do
        Keys[row.identifier] = Keys[row.identifier] or {}
        Keys[row.identifier][#Keys[row.identifier] + 1] = {
            hotel   = row.hotel,
            room    = tonumber(row.room),
            expires = tonumber(row.expires),
        }
    end
end)

CreateThread(function()
    while true do
        Wait(300000)
        local now = os.time()
        for _, keys in pairs(Keys) do
            for i = #keys, 1, -1 do
                if keys[i].expires and tonumber(keys[i].expires) <= now then
                    table.remove(keys, i)
                end
            end
        end
    end
end)

exports("GiveHotelKey",   Give)
exports("RemoveHotelKey", Remove)
exports("HasHotelKey",    function(src, hotelId, roomId)
    return Has(Main().GetIdentifier(src), hotelId, tonumber(roomId))
end)
exports("GetHotelKeys",   function(src)
    return Get(Main().GetIdentifier(src))
end)

return { Get = Get, Has = Has, Give = Give, Remove = Remove }
