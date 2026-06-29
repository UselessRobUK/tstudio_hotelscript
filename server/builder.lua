--========================================================--
-- Standalone Hotel Framework
-- server/builder.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Builder = Hotel.Builder or {}

RegisterNetEvent("hotel:saveLayout", function(data)
    local src = source

    if Hotel.IsAdmin and not Hotel.IsAdmin(src) then
        return Hotel.Notify(src, "No permission.", "error")
    end

    if type(data) ~= "table" or not data.id then
        return Hotel.Notify(src, "Invalid layout.", "error")
    end

    if Hotel.Persistence and Hotel.Persistence.SaveRuntimeHotel then
        Hotel.Persistence.SaveRuntimeHotel(data.id, data)
    end

    if Hotel.RegisterHotel then
        Hotel.RegisterHotel(data.id, data)
    end

    Hotel.Notify(src, "Hotel layout saved.", "success")
end)

RegisterNetEvent("hotel:deleteLayout", function(hotelId)
    local src = source

    if Hotel.IsAdmin and not Hotel.IsAdmin(src) then
        return Hotel.Notify(src, "No permission.", "error")
    end

    if not hotelId then
        return Hotel.Notify(src, "Missing hotel ID.", "error")
    end

    local layouts = Hotel.Persistence.ReadJson("data/layouts.json") or {}
    layouts[hotelId] = nil

    Hotel.Persistence.SaveLayouts(layouts)

    if Hotel.UnregisterHotel then
        Hotel.UnregisterHotel(hotelId)
    end

    Hotel.Notify(src, "Hotel layout deleted.", "success")
end)

RegisterNetEvent("hotel:getLayouts", function()
    local src = source

    if Hotel.IsAdmin and not Hotel.IsAdmin(src) then
        return Hotel.Notify(src, "No permission.", "error")
    end

    local layouts = Hotel.Persistence.ReadJson("data/layouts.json") or {}

    TriggerClientEvent("hotel:receiveLayouts", src, layouts)
end)

exports("SaveHotelLayout", function(data)
    if type(data) ~= "table" or not data.id then
        return false
    end

    if Hotel.Persistence and Hotel.Persistence.SaveRuntimeHotel then
        Hotel.Persistence.SaveRuntimeHotel(data.id, data)
    end

    if Hotel.RegisterHotel then
        Hotel.RegisterHotel(data.id, data)
    end

    return true
end)
