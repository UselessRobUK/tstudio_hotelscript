local Hotels = require "configs.shared.hotels"

local function Registry()    return require "server.registry" end
local function Persistence() return require "server.persistence" end
local function Stash()       return require "server.stash" end
local function Main()        return require "server.main" end
local function Security()    return require "server.security" end

---@return table
local function GetHotels()
    local all = {}
    for _, hotel in pairs(Hotels) do all[hotel.id] = hotel end
    for hotelId, hotel in pairs(Registry().GetAllHotels()) do all[hotelId] = hotel end
    return all
end

---@return boolean
local function Reload()
    Persistence().LoadLayouts()
    return true
end

RegisterCommand("hotel_reload", function(src)
    if src ~= 0 and not Security().IsAdmin(src) then
        return Main().Notify(src, "No permission.", "error")
    end
    Reload()
    if src == 0 then print("^2[HOTEL]^7 Config reloaded.") else Main().Notify(src, "Hotel config reloaded.", "success") end
end)

lib.callback.register("hotel:getConfigHotels", function(_)
    return GetHotels()
end)

exports("HotelReloadConfig",    Reload)
exports("HotelGetConfigHotels", GetHotels)

return { GetHotels = GetHotels, Reload = Reload }
