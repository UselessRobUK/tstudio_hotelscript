local Config = require "configs.shared.main"
local Hotels = require "configs.shared.hotels"
local Rooms  = require "configs.shared.rooms"
local State  = require "server.state"

---@param src number
---@return string|nil
local function GetIdentifier(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:find("license:") then return id end
    end
    return GetPlayerIdentifier(src, 0)
end

---@param hotelId string
---@return table|nil
local function GetHotel(hotelId)
    for _, hotel in pairs(Hotels) do
        if hotel.id == hotelId then return hotel end
    end
    return nil
end

---@param hotelId string
---@param roomId number
---@return table|nil, table|nil
local function GetRoom(hotelId, roomId)
    local hotel = GetHotel(hotelId)
    if hotel and hotel.rooms then
        for _, room in pairs(hotel.rooms) do
            if tonumber(room.id) == tonumber(roomId) then
                return room, hotel
            end
        end
    end
    if Rooms[hotelId] then
        for _, room in pairs(Rooms[hotelId]) do
            if tonumber(room.id) == tonumber(roomId) then
                return room, hotel
            end
        end
    end
    return nil, hotel
end

---@param src number
---@param msg string
---@param notifyType? string
local function Notify(src, msg, notifyType)
    TriggerClientEvent("hotel:notify", src, msg, notifyType or "inform")
end

-- Expose for other server modules via require "server.main"
local M = {
    GetIdentifier = GetIdentifier,
    GetHotel      = GetHotel,
    GetRoom       = GetRoom,
    Notify        = Notify,
}

CreateThread(function()
    Wait(1000)
    TriggerEvent("hotel:serverReady")
    print("^2[HOTEL]^7 Server loaded.")
end)

AddEventHandler("playerJoining", function()
    local src        = source
    local identifier = GetIdentifier(src)
    if not identifier then return end

    local rows = MySQL.query.await(
        "SELECT * FROM hotel_rentals WHERE identifier = ? AND expires > ?",
        { identifier, os.time() }
    )

    State.Rentals[identifier] = rows or {}
    TriggerClientEvent("hotel:syncKeys", src, rows or {})
end)

lib.callback.register("hotel:getRooms", function(src, hotelId)
    local hotel = GetHotel(hotelId)
    return (hotel and hotel.rooms) or Rooms[hotelId] or {}
end)

lib.callback.register("hotel:checkRoomAccess", function(src, hotelId, roomId, action)
    local identifier = GetIdentifier(src)
    if not identifier then return false end
    for _, rental in pairs(State.Rentals[identifier] or {}) do
        if rental.hotel == hotelId
        and tonumber(rental.room) == tonumber(roomId)
        and tonumber(rental.expires) > os.time() then
            return true
        end
    end
    return false
end)


CreateThread(function()
    while true do
        Wait(Config.AutoExpireCheck * 1000)
        local now = os.time()

        for identifier, rentals in pairs(State.Rentals) do
            for i = #rentals, 1, -1 do
                if tonumber(rentals[i].expires) <= now then
                    MySQL.query.await(
                        "DELETE FROM hotel_rentals WHERE identifier = ? AND hotel = ? AND room = ?",
                        { identifier, rentals[i].hotel, rentals[i].room }
                    )
                    table.remove(rentals, i)
                end
            end
            if #rentals == 0 then State.Rentals[identifier] = nil end
        end
    end
end)

return M
