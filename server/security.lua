local Config = require "configs.shared.main"

local RequestLog = {}
local Tokens     = {}

local function Main() return require "server.main" end

---@param src number
---@return boolean
local function IsAdmin(src)
    if src == 0 then return true end
    for _, ace in pairs(Config.AdminAces or { "hotel.admin", "admin" }) do
        if IsPlayerAceAllowed(src, ace) then return true end
    end
    local identifier = Main().GetIdentifier(src)
    return Config.AdminIdentifiers[identifier] == true
end

---@param src number
---@param key? string
---@param limit? number
---@param seconds? number
---@return boolean
local function IsSpamming(src, key, limit, seconds)
    key     = key or "default"
    limit   = tonumber(limit) or 10
    seconds = tonumber(seconds) or 5

    RequestLog[src]       = RequestLog[src] or {}
    RequestLog[src][key]  = RequestLog[src][key] or {}

    local now  = os.time()
    local list = RequestLog[src][key]
    for i = #list, 1, -1 do
        if now - list[i] > seconds then table.remove(list, i) end
    end
    list[#list + 1] = now
    return #list > limit
end

---@param src number
---@param key? string
---@return string
local function GenerateToken(src, key)
    key = key or "default"
    Tokens[src]      = Tokens[src] or {}
    local token      = ("%s:%s:%s"):format(src, key, math.random(100000, 999999))
    Tokens[src][key] = { token = token, expires = os.time() + 60 }
    return token
end

---@param src number
---@param key? string
---@param token string
---@return boolean
local function ValidateToken(src, key, token)
    key = key or "default"
    if not Tokens[src] or not Tokens[src][key] then return false end
    local data = Tokens[src][key]
    if data.expires < os.time() then Tokens[src][key] = nil return false end
    return data.token == token
end

---@param src number
---@param coords vector3
---@param maxDistance? number
---@return boolean
local function DistanceCheck(src, coords, maxDistance)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    return #(GetEntityCoords(ped) - vector3(coords.x, coords.y, coords.z)) <= (maxDistance or 5.0)
end

AddEventHandler("playerDropped", function()
    local src      = source
    RequestLog[src] = nil
    Tokens[src]     = nil
end)

exports("HotelIsAdmin",        IsAdmin)
exports("HotelIsSpamming",     IsSpamming)
exports("HotelGenerateToken",  GenerateToken)
exports("HotelValidateToken",  ValidateToken)
exports("HotelDistanceCheck",  DistanceCheck)

return { IsAdmin = IsAdmin, IsSpamming = IsSpamming, GenerateToken = GenerateToken, ValidateToken = ValidateToken, DistanceCheck = DistanceCheck }
