--========================================================--
-- Standalone Hotel Framework
-- server/config_loader.lua
--========================================================--

Hotel = Hotel or {}
Hotel.ConfigLoader = Hotel.ConfigLoader or {}

function Hotel.ConfigLoader.GetHotels()
    local hotels = {}

    for _, hotel in pairs(Config.Hotels or {}) do
        hotels[hotel.id] = hotel
    end

    if Hotel.Registry then
        for hotelId, hotel in pairs(Hotel.Registry) do
            hotels[hotelId] = hotel
        end
    end

    return hotels
end

function Hotel.ConfigLoader.Reload()
    if Hotel.Persistence and Hotel.Persistence.LoadLayouts then
        Hotel.Persistence.LoadLayouts()
    end

    if Hotel.Stash and Hotel.Stash.RegisterAll then
        Hotel.Stash.RegisterAll()
    end

    return true
end

RegisterCommand("hotel_reload", function(src)
    if src ~= 0 and Hotel.IsAdmin and not Hotel.IsAdmin(src) then
        return Hotel.Notify(src, "No permission.", "error")
    end

    Hotel.ConfigLoader.Reload()

    if src == 0 then
        print("^2[HOTEL]^7 Config reloaded.")
    else
        Hotel.Notify(src, "Hotel config reloaded.", "success")
    end
end)

RegisterNetEvent("hotel:getConfigHotels", function()
    local src = source

    TriggerClientEvent(
        "hotel:receiveConfigHotels",
        src,
        Hotel.ConfigLoader.GetHotels()
    )
end)

exports("HotelReloadConfig", Hotel.ConfigLoader.Reload)
exports("HotelGetConfigHotels", Hotel.ConfigLoader.GetHotels)
