--========================================================--
-- Standalone Hotel Framework
-- server/security.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Security = Hotel.Security or {}

local RequestLog = {}
local Tokens = {}

function Hotel.Security.IsAdmin(src)
    if src == 0 then return true end

    for _, ace in pairs(Config.AdminAces or { "hotel.admin", "admin" }) do
        if IsPlayerAceAllowed(src, ace) then
            return true
        end
    end

    local identifier = Hotel.GetIdentifier and Hotel.GetIdentifier(src)
    return Config.AdminIdentifiers and Config.AdminIdentifiers[identifier] == true
end

Hotel.IsAdmin = Hotel.Security.IsAdmin

function Hotel.Security.IsSpamming(src, key, limit, seconds)
    key = key or "default"
    limit = tonumber(limit) or 10
    seconds = tonumber(seconds) or 5

    RequestLog[src] = RequestLog[src] or {}
    RequestLog[src][key] = RequestLog[src][key] or {}

    local now = os.time()
    local list = RequestLog[src][key]

    for i = #list, 1, -1 do
        if now - list[i] > seconds then
            table.remove(list, i)
        end
    end

    list[#list + 1] = now

    return #list > limit
end

function Hotel.Security.GenerateToken(src, key)
    key = key or "default"

    Tokens[src] = Tokens[src] or {}

    local token = ("%s:%s:%s"):format(
        src,
        key,
        math.random(100000, 999999)
    )

    Tokens[src][key] = {
        token = token,
        expires = os.time() + 60
    }

    return token
end

function Hotel.Security.ValidateToken(src, key, token)
    key = key or "default"

    if not Tokens[src] or not Tokens[src][key] then
        return false
    end

    local data = Tokens[src][key]

    if data.expires < os.time() then
        Tokens[src][key] = nil
        return false
    end

    return data.token == token
end

function Hotel.Security.DistanceCheck(src, coords, maxDistance)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end

    local playerCoords = GetEntityCoords(ped)

    return #(playerCoords - vector3(coords.x, coords.y, coords.z)) <= (maxDistance or 5.0)
end

AddEventHandler("playerDropped", function()
    local src = source
    RequestLog[src] = nil
    Tokens[src] = nil
end)

exports("HotelIsAdmin", Hotel.Security.IsAdmin)
exports("HotelIsSpamming", Hotel.Security.IsSpamming)
exports("HotelGenerateToken", Hotel.Security.GenerateToken)
exports("HotelValidateToken", Hotel.Security.ValidateToken)
exports("HotelDistanceCheck", Hotel.Security.DistanceCheck)
