--========================================================--
-- Standalone Hotel Framework
-- server/main.lua
--========================================================--

Hotel = Hotel or {}

Hotel.Rentals = {}
Hotel.Bookings = {}
Hotel.Revenue = {}
Hotel.Complaints = {}
Hotel.RoomStates = {}

----------------------------------------------------------
-- Startup
----------------------------------------------------------

CreateThread(function()
    print("^2[HOTEL]^7 Server starting...")

    Wait(1000)

    if not MySQL then
        print("^1[HOTEL ERROR]^7 oxmysql not found. Add @oxmysql/lib/MySQL.lua to fxmanifest.")
    end

    TriggerEvent("hotel:serverReady")

    print("^2[HOTEL]^7 Server loaded.")
end)

----------------------------------------------------------
-- Player Identifier
----------------------------------------------------------

function Hotel.GetIdentifier(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:find("license:") then
            return id
        end
    end

    return GetPlayerIdentifier(src, 0)
end

----------------------------------------------------------
-- Get Hotel
----------------------------------------------------------

function Hotel.GetHotel(hotelId)
    for _, hotel in pairs(Config.Hotels or {}) do
        if hotel.id == hotelId then
            return hotel
        end
    end

    return nil
end

----------------------------------------------------------
-- Get Room
----------------------------------------------------------

function Hotel.GetRoom(hotelId, roomId)
    local hotel = Hotel.GetHotel(hotelId)

    if hotel and hotel.rooms then
        for _, room in pairs(hotel.rooms) do
            if tonumber(room.id) == tonumber(roomId) then
                return room, hotel
            end
        end
    end

    if Config.Rooms and Config.Rooms[hotelId] then
        for _, room in pairs(Config.Rooms[hotelId]) do
            if tonumber(room.id) == tonumber(roomId) then
                return room, hotel
            end
        end
    end

    return nil, hotel
end

----------------------------------------------------------
-- Notifications
----------------------------------------------------------

function Hotel.Notify(src, msg, notifyType)
    TriggerClientEvent("hotel:notify", src, msg, notifyType or "inform")
end

----------------------------------------------------------
-- Load Player Rentals
----------------------------------------------------------

AddEventHandler("playerJoining", function()
    local src = source
    local identifier = Hotel.GetIdentifier(src)

    if not identifier or not MySQL then return end

    local rows = MySQL.query.await(
        "SELECT * FROM hotel_rentals WHERE identifier = ? AND expires > ?",
        { identifier, os.time() }
    )

    Hotel.Rentals[identifier] = rows or {}

    TriggerClientEvent("hotel:syncKeys", src, rows or {})
end)

----------------------------------------------------------
-- Rent Room
----------------------------------------------------------

RegisterNetEvent("hotel:rentRoom", function(data)
    local src = source

    if type(data) ~= "table" then return end

    local hotelId = data.hotelId
    local roomId = tonumber(data.roomId)
    local payment = data.payment or Config.DefaultPayment or "cash"

    local identifier = Hotel.GetIdentifier(src)
    if not identifier then return end

    local room = Hotel.GetRoom(hotelId, roomId)
    if not room then
        return Hotel.Notify(src, "Invalid room.", "error")
    end

    if Hotel.Rentals[identifier] and #Hotel.Rentals[identifier] > 0 then
        return Hotel.Notify(src, "You already have an active hotel room.", "error")
    end

    local price = tonumber(room.price) or 0

    if not exports[GetCurrentResourceName()]:RemoveMoney(src, price, payment) then
        return Hotel.Notify(src, "You do not have enough money.", "error")
    end

    local expires = os.time() + ((tonumber(room.duration) or 24) * 3600)

    local rental = {
        identifier = identifier,
        hotel = hotelId,
        room = roomId,
        expires = expires
    }

    Hotel.Rentals[identifier] = { rental }

    if MySQL then
        MySQL.insert.await(
            "INSERT INTO hotel_rentals (identifier, hotel, room, expires) VALUES (?, ?, ?, ?)",
            { identifier, hotelId, roomId, expires }
        )
    end

    Hotel.Revenue[hotelId] = (Hotel.Revenue[hotelId] or 0) + price

    TriggerClientEvent("hotel:receiveKey", src, {
        hotel = hotelId,
        room = roomId,
        expires = expires
    })

    TriggerClientEvent("hotel:anim:receiveKey", src)
    Hotel.Notify(src, "Room rented successfully.", "success")
end)

----------------------------------------------------------
-- Get Rooms
----------------------------------------------------------

RegisterNetEvent("hotel:getRooms", function(hotelId)
    local src = source
    local rooms = {}

    local hotel = Hotel.GetHotel(hotelId)

    if hotel and hotel.rooms then
        rooms = hotel.rooms
    elseif Config.Rooms and Config.Rooms[hotelId] then
        rooms = Config.Rooms[hotelId]
    end

    TriggerClientEvent("hotel:receiveRooms", src, hotelId, rooms)
end)

----------------------------------------------------------
-- Room Access
----------------------------------------------------------

RegisterNetEvent("hotel:checkRoomAccess", function(hotelId, roomId, action)
    local src = source
    local identifier = Hotel.GetIdentifier(src)

    if not identifier then return end

    local rentals = Hotel.Rentals[identifier] or {}

    for _, rental in pairs(rentals) do
        if rental.hotel == hotelId
        and tonumber(rental.room) == tonumber(roomId)
        and tonumber(rental.expires) > os.time() then

            if action then
                TriggerClientEvent("hotel:roomActionApproved", src, action, hotelId, roomId)
            else
                TriggerClientEvent("hotel:roomAccessApproved", src, hotelId, roomId)
            end

            return
        end
    end

    TriggerClientEvent("hotel:roomAccessDenied", src)
end)

----------------------------------------------------------
-- Stash Access
----------------------------------------------------------

RegisterNetEvent("hotel:requestStashAccess", function(hotelId, roomId)
    local src = source
    TriggerEvent("hotel:checkRoomAccess", hotelId, roomId, "stash")
end)

RegisterNetEvent("hotel:openRoomStash", function(hotelId, roomId)
    local src = source
    TriggerClientEvent("hotel:stashApproved", src, hotelId, roomId)
end)

----------------------------------------------------------
-- Expiry Thread
----------------------------------------------------------

CreateThread(function()
    while true do
        Wait((Config.HotelSettings and Config.HotelSettings.AutoExpireCheck or 60) * 1000)

        local now = os.time()

        for identifier, rentals in pairs(Hotel.Rentals) do
            for i = #rentals, 1, -1 do
                if tonumber(rentals[i].expires) <= now then
                    if MySQL then
                        MySQL.query.await(
                            "DELETE FROM hotel_rentals WHERE identifier = ? AND hotel = ? AND room = ?",
                            { identifier, rentals[i].hotel, rentals[i].room }
                        )
                    end

                    table.remove(rentals, i)
                end
            end

            if #rentals == 0 then
                Hotel.Rentals[identifier] = nil
            end
        end
    end
end)

----------------------------------------------------------
-- Exports
----------------------------------------------------------

exports("GetIdentifier", Hotel.GetIdentifier)
exports("GetHotel", Hotel.GetHotel)
exports("GetRoom", Hotel.GetRoom)

exports("GetPlayerRentals", function(src)
    local identifier = Hotel.GetIdentifier(src)
    return Hotel.Rentals[identifier] or {}
end)

exports("HasRoomAccess", function(src, hotelId, roomId)
    local identifier = Hotel.GetIdentifier(src)
    local rentals = Hotel.Rentals[identifier] or {}

    for _, rental in pairs(rentals) do
        if rental.hotel == hotelId
        and tonumber(rental.room) == tonumber(roomId)
        and tonumber(rental.expires) > os.time() then
            return true
        end
    end

    return false
end)
