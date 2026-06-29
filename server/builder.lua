local function Main()        return require "server.main" end
local function Security()    return require "server.security" end
local function Persistence() return require "server.persistence" end
local function Registry()    return require "server.registry" end

RegisterNetEvent("hotel:saveLayout", function(data)
    local src = source
    if not Security().IsAdmin(src) then return Main().Notify(src, "No permission.", "error") end
    if type(data) ~= "table" or not data.id then return Main().Notify(src, "Invalid layout.", "error") end
    Persistence().SaveRuntimeHotel(data.id, data)
    Registry().RegisterHotel(data.id, data)
    Main().Notify(src, "Hotel layout saved.", "success")
end)

RegisterNetEvent("hotel:deleteLayout", function(hotelId)
    local src = source
    if not Security().IsAdmin(src) then return Main().Notify(src, "No permission.", "error") end
    if not hotelId then return Main().Notify(src, "Missing hotel ID.", "error") end
    local layouts = Persistence().ReadJson("data/layouts.json") or {}
    layouts[hotelId] = nil
    Persistence().SaveLayouts(layouts)
    Registry().UnregisterHotel(hotelId)
    Main().Notify(src, "Hotel layout deleted.", "success")
end)

RegisterNetEvent("hotel:getLayouts", function()
    local src = source
    if not Security().IsAdmin(src) then return Main().Notify(src, "No permission.", "error") end
    local layouts = Persistence().ReadJson("data/layouts.json") or {}
    TriggerClientEvent("hotel:receiveLayouts", src, layouts)
end)

exports("SaveHotelLayout", function(data)
    if type(data) ~= "table" or not data.id then return false end
    Persistence().SaveRuntimeHotel(data.id, data)
    Registry().RegisterHotel(data.id, data)
    return true
end)
