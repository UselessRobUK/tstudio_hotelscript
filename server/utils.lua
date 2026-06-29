--========================================================--
-- Standalone Hotel Framework
-- server/utils.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Utils = Hotel.Utils or {}

function Hotel.Utils.Debug(...)
    if not Config.Debug then return end
    print("^3[HOTEL DEBUG]^7", ...)
end

function Hotel.Utils.Error(...)
    print("^1[HOTEL ERROR]^7", ...)
end

function Hotel.Utils.Success(...)
    print("^2[HOTEL]^7", ...)
end

function Hotel.Utils.TableCount(tbl)
    local count = 0

    for _ in pairs(tbl or {}) do
        count = count + 1
    end

    return count
end

function Hotel.Utils.CopyTable(tbl)
    if type(tbl) ~= "table" then return tbl end

    local copy = {}

    for k, v in pairs(tbl) do
        copy[k] = Hotel.Utils.CopyTable(v)
    end

    return copy
end

function Hotel.Utils.Clamp(num, min, max)
    num = tonumber(num) or 0
    min = tonumber(min) or num
    max = tonumber(max) or num

    if num < min then return min end
    if num > max then return max end

    return num
end

function Hotel.Utils.Round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor((tonumber(num) or 0) * mult + 0.5) / mult
end

function Hotel.Utils.FormatMoney(amount)
    return ("£%s"):format(tonumber(amount) or 0)
end

function Hotel.Utils.SafeJsonEncode(data)
    local ok, encoded = pcall(json.encode, data)

    if not ok then
        return "{}"
    end

    return encoded
end

function Hotel.Utils.SafeJsonDecode(data)
    if not data or data == "" then return nil end

    local ok, decoded = pcall(json.decode, data)

    if not ok then
        return nil
    end

    return decoded
end

function Hotel.Utils.GetPlayerNameSafe(src)
    return GetPlayerName(src) or ("Player %s"):format(src)
end

function Hotel.Utils.FindOnlinePlayerByIdentifier(identifier)
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)

        if Hotel.GetIdentifier(src) == identifier then
            return src
        end
    end

    return nil
end

function Hotel.Utils.IsValidHotelId(hotelId)
    return type(hotelId) == "string" and hotelId ~= ""
end

function Hotel.Utils.IsValidRoomId(roomId)
    return tonumber(roomId) ~= nil
end

function Hotel.Utils.Timestamp()
    return os.time()
end

function Hotel.Utils.DateTime(timestamp)
    return os.date("%d/%m/%Y %H:%M:%S", timestamp or os.time())
end

exports("HotelDebug", Hotel.Utils.Debug)
exports("HotelError", Hotel.Utils.Error)
exports("HotelSuccess", Hotel.Utils.Success)
exports("HotelTableCount", Hotel.Utils.TableCount)
exports("HotelCopyTable", Hotel.Utils.CopyTable)
exports("HotelClamp", Hotel.Utils.Clamp)
exports("HotelRound", Hotel.Utils.Round)
exports("HotelFormatMoney", Hotel.Utils.FormatMoney)
exports("HotelSafeJsonEncode", Hotel.Utils.SafeJsonEncode)
exports("HotelSafeJsonDecode", Hotel.Utils.SafeJsonDecode)
exports("HotelFindOnlinePlayerByIdentifier", Hotel.Utils.FindOnlinePlayerByIdentifier)
