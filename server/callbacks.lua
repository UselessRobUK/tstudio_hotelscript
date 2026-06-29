local State = require "server.state"
local Rooms = require "configs.shared.rooms"

local Requests = {}

RegisterNetEvent("hotel:callback:request", function(name, requestId, data)
    local src = source
    if type(name) ~= "string" or not requestId then return end

    local cb = State.Callbacks[name]
    if not cb then
        TriggerClientEvent("hotel:callback:response", src, requestId, nil)
        return
    end

    local ok, result = pcall(cb, src, data)
    if not ok then
        print(("^1[HOTEL CALLBACK ERROR]^7 %s: %s"):format(name, result))
        result = nil
    end

    TriggerClientEvent("hotel:callback:response", src, requestId, result)
end)

---@param name string
---@param cb function
---@return boolean
local function RegisterCallback(name, cb)
    if type(name) ~= "string" or type(cb) ~= "function" then return false end
    State.Callbacks[name] = cb
    return true
end

RegisterCallback("getRooms", function(_, data)
    local Main    = require "server.main"
    local hotelId = data and data.hotelId
    local hotel   = Main.GetHotel(hotelId)
    if hotel and hotel.rooms then return hotel.rooms end
    return Rooms[hotelId] or {}
end)

RegisterCallback("getRental", function(src)
    local Main       = require "server.main"
    local identifier = Main.GetIdentifier(src)
    return State.Rentals[identifier] or {}
end)

RegisterCallback("hasRoomAccess", function(src, data)
    return exports[GetCurrentResourceName()]:HasRoomAccess(src, data.hotelId, tonumber(data.roomId))
end)

RegisterCallback("getDashboard", function(src, data)
    local hotelId = data and data.hotelId
    local active  = 0

    for _, rentals in pairs(State.Rentals or {}) do
        for _, rental in pairs(rentals) do
            if rental.hotel == hotelId and tonumber(rental.expires) > os.time() then
                active = active + 1
            end
        end
    end

    return {
        hotel      = hotelId,
        active     = active,
        revenue    = State.Revenue[hotelId] or 0,
        complaints = State.Complaints[hotelId] or {},
    }
end)

exports("RegisterHotelCallback", RegisterCallback)

return { RegisterCallback = RegisterCallback }
