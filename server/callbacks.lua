--========================================================--
-- Standalone Hotel Framework
-- server/callbacks.lua
--========================================================--

Hotel.Callbacks = Hotel.Callbacks or {}

local Requests = {}

RegisterNetEvent("hotel:callback:request", function(name, requestId, data)
    local src = source

    if type(name) ~= "string" or not requestId then return end
    if not Hotel.Callbacks[name] then
        TriggerClientEvent("hotel:callback:response", src, requestId, nil)
        return
    end

    local ok, result = pcall(Hotel.Callbacks[name], src, data)

    if not ok then
        print(("^1[HOTEL CALLBACK ERROR]^7 %s: %s"):format(name, result))
        result = nil
    end

    TriggerClientEvent("hotel:callback:response", src, requestId, result)
end)

function Hotel.RegisterCallback(name, cb)
    if type(name) ~= "string" or type(cb) ~= "function" then
        return false
    end

    Hotel.Callbacks[name] = cb
    return true
end

Hotel.RegisterCallback("getRooms", function(_, data)
    local hotelId = data and data.hotelId
    local hotel = Hotel.GetHotel(hotelId)

    if hotel and hotel.rooms then
        return hotel.rooms
    end

    return Config.Rooms and Config.Rooms[hotelId] or {}
end)

Hotel.RegisterCallback("getRental", function(src)
    local identifier = Hotel.GetIdentifier(src)
    return Hotel.Rentals[identifier] or {}
end)

Hotel.RegisterCallback("hasRoomAccess", function(src, data)
    return exports[GetCurrentResourceName()]:HasRoomAccess(
        src,
        data.hotelId,
        tonumber(data.roomId)
    )
end)

Hotel.RegisterCallback("getDashboard", function(src, data)
    local hotelId = data and data.hotelId
    if Hotel.IsBoss and not Hotel.IsBoss(src, hotelId) then
        return nil
    end

    local active = 0

    for _, rentals in pairs(Hotel.Rentals or {}) do
        for _, rental in pairs(rentals) do
            if rental.hotel == hotelId and tonumber(rental.expires) > os.time() then
                active = active + 1
            end
        end
    end

    return {
        hotel = hotelId,
        active = active,
        revenue = Hotel.Revenue[hotelId] or 0,
        complaints = Hotel.Complaints[hotelId] or {}
    }
end)

exports("RegisterHotelCallback", Hotel.RegisterCallback)
