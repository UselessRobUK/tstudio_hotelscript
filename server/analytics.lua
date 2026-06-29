local Stats = { rentals = 0, bookings = 0, revenue = 0, complaints = 0, evictions = 0, fines = 0, cleaning = 0 }

local function Main()     return require "server.main" end
local function Security() return require "server.security" end

---@param stat string
---@param amount? number
---@return number
local function Add(stat, amount)
    amount    = tonumber(amount) or 1
    Stats[stat] = (Stats[stat] or 0) + amount
    return Stats[stat]
end

---@return table
local function Get()
    return Stats
end

RegisterNetEvent("hotel:analytics:add", function(stat, amount)
    if source ~= 0 and not Security().IsAdmin(source) then return end
    Add(stat, amount)
end)

RegisterNetEvent("hotel:analytics:get", function()
    local src = source
    if not Security().IsAdmin(src) then return Main().Notify(src, "No permission.", "error") end
    TriggerClientEvent("hotel:analytics:data", src, Get())
end)

exports("HotelAnalyticsAdd", Add)
exports("HotelAnalyticsGet", Get)

return { Add = Add, Get = Get }
