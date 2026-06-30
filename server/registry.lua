local Hotels = require "configs.shared.hotels"

local Registry = {}

---@param hotelId string
---@param data table
---@return boolean
local function RegisterHotel(hotelId, data)
    if not hotelId or type(data) ~= "table" then return false end
    data.id = hotelId
    Registry[hotelId] = data
    return true
end

---@param hotelId string
---@return boolean
local function UnregisterHotel(hotelId)
    Registry[hotelId] = nil
    return true
end

---@param hotelId string
---@return table|nil
local function GetRegisteredHotel(hotelId)
    if Registry[hotelId] then return Registry[hotelId] end
    return (require "server.main").GetHotel(hotelId)
end

---@return table
local function GetAllHotels()
    local all = {}
    for _, hotel in pairs(Hotels) do all[hotel.id] = hotel end
    for id, hotel in pairs(Registry) do all[id] = hotel end
    return all
end

lib.callback.register("hotel:getHotels", function(_)
    return GetAllHotels()
end)

RegisterNetEvent("hotel:registerRuntimeHotel", function(hotelId, data)
    local src  = source
    local Main = require "server.main"
    if not RegisterHotel(hotelId, data) then return end
    Main.Notify(src, "Hotel registered.", "success")
end)

RegisterNetEvent("hotel:unregisterRuntimeHotel", function(hotelId)
    local src  = source
    local Main = require "server.main"
    UnregisterHotel(hotelId)
    Main.Notify(src, "Hotel unregistered.", "success")
end)

exports("RegisterHotel",        RegisterHotel)
exports("UnregisterHotel",      UnregisterHotel)
exports("GetRegisteredHotel",   GetRegisteredHotel)
exports("GetAllHotels",         GetAllHotels)

return { RegisterHotel = RegisterHotel, UnregisterHotel = UnregisterHotel, GetAllHotels = GetAllHotels }
