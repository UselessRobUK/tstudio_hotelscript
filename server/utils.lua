local Config = require "configs.shared.main"

---@param ... any
local function Debug(...)
    if not Config.Debug then return end
    print("^3[HOTEL DEBUG]^7", ...)
end

---@param ... any
local function Error(...)
    print("^1[HOTEL ERROR]^7", ...)
end

---@param ... any
local function Success(...)
    print("^2[HOTEL]^7", ...)
end

---@param tbl table
---@return number
local function TableCount(tbl)
    local count = 0
    for _ in pairs(tbl or {}) do count = count + 1 end
    return count
end

---@param tbl table
---@return table
local function CopyTable(tbl)
    if type(tbl) ~= "table" then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do copy[k] = CopyTable(v) end
    return copy
end

---@param num number
---@param min number
---@param max number
---@return number
local function Clamp(num, min, max)
    num = tonumber(num) or 0
    if num < min then return min end
    if num > max then return max end
    return num
end

---@param num number
---@param decimals? number
---@return number
local function Round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor((tonumber(num) or 0) * mult + 0.5) / mult
end

---@param amount number
---@return string
local function FormatMoney(amount)
    return ("%s%s"):format(Config.Currency or "£", tonumber(amount) or 0)
end

---@param data any
---@return string
local function SafeJsonEncode(data)
    local ok, encoded = pcall(json.encode, data)
    return ok and encoded or "{}"
end

---@param data string
---@return any
local function SafeJsonDecode(data)
    if not data or data == "" then return nil end
    local ok, decoded = pcall(json.decode, data)
    return ok and decoded or nil
end

---@param src number
---@return string
local function GetPlayerNameSafe(src)
    return GetPlayerName(src) or ("Player %s"):format(src)
end

---@param identifier string
---@return number|nil
local function FindOnlinePlayerByIdentifier(identifier)
    local Main = require "server.main"
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if Main.GetIdentifier(src) == identifier then
            return src
        end
    end
    return nil
end

---@return number
local function Timestamp()
    return os.time()
end

---@param timestamp? number
---@return string
local function DateTime(timestamp)
    return os.date("%d/%m/%Y %H:%M:%S", timestamp or os.time())
end

return {
    Debug                       = Debug,
    Error                       = Error,
    Success                     = Success,
    TableCount                  = TableCount,
    CopyTable                   = CopyTable,
    Clamp                       = Clamp,
    Round                       = Round,
    FormatMoney                 = FormatMoney,
    SafeJsonEncode              = SafeJsonEncode,
    SafeJsonDecode              = SafeJsonDecode,
    GetPlayerNameSafe           = GetPlayerNameSafe,
    FindOnlinePlayerByIdentifier = FindOnlinePlayerByIdentifier,
    Timestamp                   = Timestamp,
    DateTime                    = DateTime,
}
