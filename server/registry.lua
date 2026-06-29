--========================================================--
-- Standalone Hotel Framework
-- server/registry.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Registry = Hotel.Registry or {}

function Hotel.RegisterHotel(hotelId, data)
    if not hotelId or type(data) ~= "table" then
        return false
    end

    data.id = hotelId
    Hotel.Registry[hotelId] = data

    return true
end

function Hotel.UnregisterHotel(hotelId)
    Hotel.Registry[hotelId] = nil
    return true
end

function Hotel.GetRegisteredHotel(hotelId)
    return Hotel.Registry[hotelId] or Hotel.GetHotel(hotelId)
end

function Hotel.GetAllHotels()
    local hotels = {}

    for _, hotel in pairs(Config.Hotels or {}) do
        hotels[hotel.id] = hotel
    end

    for id, hotel in pairs(Hotel.Registry or {}) do
        hotels[id] = hotel
    end

    return hotels
end

RegisterNetEvent("hotel:getHotels", function()
    local src = source
    TriggerClientEvent("hotel:receiveHotels", src, Hotel.GetAllHotels())
end)

RegisterNetEvent("hotel:registerRuntimeHotel", function(hotelId, data)
    local src = source

    if Hotel.IsAdmin and not Hotel.IsAdmin(src) then
        return Hotel.Notify(src, "No permission.", "error")
    end

    if Hotel.RegisterHotel(hotelId, data) then
        Hotel.Notify(src, "Hotel registered.", "success")
    end
end)

RegisterNetEvent("hotel:unregisterRuntimeHotel", function(hotelId)
    local src = source

    if Hotel.IsAdmin and not Hotel.IsAdmin(src) then
        return Hotel.Notify(src, "No permission.", "error")
    end

    Hotel.UnregisterHotel(hotelId)
    Hotel.Notify(src, "Hotel unregistered.", "success")
end)

exports("RegisterHotel", Hotel.RegisterHotel)
exports("UnregisterHotel", Hotel.UnregisterHotel)
exports("GetRegisteredHotel", Hotel.GetRegisteredHotel)
exports("GetAllHotels", Hotel.GetAllHotels)
