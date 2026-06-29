--========================================================--
-- Standalone Hotel Framework
-- server/keys.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Keys = Hotel.Keys or {}

----------------------------------------------------------
-- Helpers
----------------------------------------------------------

local function Notify(src, msg, notifyType)
    if Hotel.Notify then
        Hotel.Notify(src, msg, notifyType or "inform")
    end
end

local function Identifier(src)
    return Hotel.GetIdentifier(src)
end

----------------------------------------------------------
-- Key Cache
----------------------------------------------------------

function Hotel.Keys.Get(identifier)
    return Hotel.Keys[identifier] or {}
end

function Hotel.Keys.Has(identifier, hotelId, roomId)
    local keys = Hotel.Keys.Get(identifier)

    local now = os.time()

    for _, key in pairs(keys) do
        if key.hotel == hotelId
        and tonumber(key.room) == tonumber(roomId)
        and (not key.expires or tonumber(key.expires) > now) then
            return true
        end
    end

    return false
end

function Hotel.Keys.Give(src, hotelId, roomId, expires)
    local identifier = Identifier(src)
    if not identifier then return false end

    Hotel.Keys[identifier] = Hotel.Keys[identifier] or {}

    for _, key in pairs(Hotel.Keys[identifier]) do
        if key.hotel == hotelId and tonumber(key.room) == tonumber(roomId) then
            key.expires = expires
            TriggerClientEvent("hotel:receiveKey", src, key)
            return true
        end
    end

    local key = {
        hotel = hotelId,
        room = tonumber(roomId),
        expires = expires
    }

    Hotel.Keys[identifier][#Hotel.Keys[identifier] + 1] = key

    if MySQL then
        MySQL.insert.await([[
            INSERT INTO hotel_keys
            (identifier, hotel, room, expires)
            VALUES (?, ?, ?, ?)
        ]], {
            identifier,
            hotelId,
            roomId,
            expires
        })
    end

    TriggerClientEvent("hotel:receiveKey", src, key)

    return true
end

function Hotel.Keys.Remove(src, hotelId, roomId)
    local identifier = Identifier(src)
    if not identifier then return false end

    local list = Hotel.Keys[identifier] or {}

    for i = #list, 1, -1 do
        local key = list[i]

        if key.hotel == hotelId
        and tonumber(key.room) == tonumber(roomId) then

            table.remove(list, i)

            if MySQL then
                MySQL.query.await(
                    "DELETE FROM hotel_keys WHERE identifier = ? AND hotel = ? AND room = ?",
                    { identifier, hotelId, tonumber(roomId) }
                )
            end

            TriggerClientEvent(
                "hotel:removeKey",
                src,
                hotelId,
                tonumber(roomId)
            )

            return true
        end
    end

    return false
end

----------------------------------------------------------
-- Sync
----------------------------------------------------------

RegisterNetEvent("hotel:syncKeys", function()
    local src = source
    local identifier = Identifier(src)

    if not identifier then return end

    TriggerClientEvent(
        "hotel:syncKeys",
        src,
        Hotel.Keys.Get(identifier)
    )
end)

----------------------------------------------------------
-- Room Entry Request
----------------------------------------------------------

RegisterNetEvent("hotel:requestRoomEntry", function(hotelId, roomId)
    local src = source
    local identifier = Identifier(src)

    if not identifier then return end

    if not Hotel.Keys.Has(identifier, hotelId, tonumber(roomId)) then
        return Notify(src, "You don't own this room key.", "error")
    end

    TriggerClientEvent(
        "hotel:roomAccessApproved",
        src,
        hotelId,
        tonumber(roomId)
    )

    TriggerClientEvent(
        "hotel:requestEnterInstance",
        src,
        hotelId,
        tonumber(roomId)
    )
end)

----------------------------------------------------------
-- Duplicate Key
----------------------------------------------------------

RegisterNetEvent("hotel:duplicateKey", function(hotelId, roomId)
    local src = source

    local rental = exports[GetCurrentResourceName()]:GetActiveHotelRental(src)

    if not rental then
        return Notify(src, "No active rental.", "error")
    end

    if rental.hotel ~= hotelId
    or tonumber(rental.room) ~= tonumber(roomId) then
        return Notify(src, "You don't own this room.", "error")
    end

    Hotel.Keys.Give(
        src,
        hotelId,
        tonumber(roomId),
        rental.expires
    )

    Notify(src, "Duplicate key issued.", "success")
end)

----------------------------------------------------------
-- Startup Load
----------------------------------------------------------

CreateThread(function()

    Wait(2500)

    if not MySQL then return end

    local rows = MySQL.query.await(
        "SELECT * FROM hotel_keys",
        {}
    )

    for _, row in pairs(rows or {}) do

        Hotel.Keys[row.identifier] =
            Hotel.Keys[row.identifier] or {}

        Hotel.Keys[row.identifier][
            #Hotel.Keys[row.identifier] + 1
        ] = {

            hotel = row.hotel,

            room = tonumber(row.room),

            expires = tonumber(row.expires)

        }

    end

end)

----------------------------------------------------------
-- Cleanup
----------------------------------------------------------

CreateThread(function()

    while true do

        Wait(300000)

        local now = os.time()

        for identifier, keys in pairs(Hotel.Keys) do

            for i = #keys, 1, -1 do

                if keys[i].expires
                and tonumber(keys[i].expires) <= now then

                    table.remove(keys, i)

                end

            end

        end

    end

end)

----------------------------------------------------------
-- Exports
----------------------------------------------------------

exports("GiveHotelKey", Hotel.Keys.Give)

exports("RemoveHotelKey", Hotel.Keys.Remove)

exports("HasHotelKey", function(src, hotelId, roomId)

    local identifier = Identifier(src)

    return Hotel.Keys.Has(
        identifier,
        hotelId,
        tonumber(roomId)
    )

end)

exports("GetHotelKeys", function(src)

    local identifier = Identifier(src)

    return Hotel.Keys.Get(identifier)

end)
