--========================================================--
-- Standalone Hotel Framework
-- server/analytics.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Analytics = Hotel.Analytics or {}

Hotel.Analytics.Stats = Hotel.Analytics.Stats or {
    rentals = 0,
    bookings = 0,
    revenue = 0,
    complaints = 0,
    evictions = 0,
    fines = 0,
    cleaning = 0
}

function Hotel.Analytics.Add(stat, amount)
    amount = tonumber(amount) or 1

    Hotel.Analytics.Stats[stat] =
        (Hotel.Analytics.Stats[stat] or 0) + amount

    return Hotel.Analytics.Stats[stat]
end

function Hotel.Analytics.Get()
    return Hotel.Analytics.Stats
end

RegisterNetEvent("hotel:analytics:add", function(stat, amount)
    if source ~= 0 and Hotel.IsAdmin and not Hotel.IsAdmin(source) then return end
    Hotel.Analytics.Add(stat, amount)
end)

RegisterNetEvent("hotel:analytics:get", function()
    local src = source

    if Hotel.IsAdmin and not Hotel.IsAdmin(src) then
        return Hotel.Notify(src, "No permission.", "error")
    end

    TriggerClientEvent("hotel:analytics:data", src, Hotel.Analytics.Get())
end)

exports("HotelAnalyticsAdd", Hotel.Analytics.Add)
exports("HotelAnalyticsGet", Hotel.Analytics.Get)
