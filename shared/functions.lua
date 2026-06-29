--========================================================--
-- Standalone Hotel Framework
-- shared/functions.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Shared = Hotel.Shared or {}

----------------------------------------------------------
-- Version
----------------------------------------------------------

Hotel.Version = "1.0.0"

----------------------------------------------------------
-- Math
----------------------------------------------------------

function Hotel.Shared.Round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor((tonumber(value) or 0) * mult + 0.5) / mult
end

function Hotel.Shared.Clamp(value, min, max)
    value = tonumber(value) or 0

    if value < min then
        return min
    end

    if value > max then
        return max
    end

    return value
end

----------------------------------------------------------
-- Tables
----------------------------------------------------------

function Hotel.Shared.DeepCopy(tbl)
    if type(tbl) ~= "table" then
        return tbl
    end

    local copy = {}

    for k, v in pairs(tbl) do
        copy[k] = Hotel.Shared.DeepCopy(v)
    end

    return copy
end

function Hotel.Shared.TableCount(tbl)
    local count = 0

    for _ in pairs(tbl or {}) do
        count = count + 1
    end

    return count
end

----------------------------------------------------------
-- JSON
----------------------------------------------------------

function Hotel.Shared.Encode(data)
    local ok, encoded = pcall(json.encode, data)

    if ok then
        return encoded
    end

    return "{}"
end

function Hotel.Shared.Decode(data)
    if not data or data == "" then
        return nil
    end

    local ok, decoded = pcall(json.decode, data)

    if ok then
        return decoded
    end

    return nil
end

----------------------------------------------------------
-- Strings
----------------------------------------------------------

function Hotel.Shared.FormatMoney(amount)
    amount = tonumber(amount) or 0
    return ("%s%s"):format(Config.Currency or "£", amount)
end

function Hotel.Shared.Trim(text)
    return tostring(text):match("^%s*(.-)%s*$")
end

----------------------------------------------------------
-- Time
----------------------------------------------------------

function Hotel.Shared.Timestamp()
    return os.time()
end

function Hotel.Shared.FormatTime(seconds)
    seconds = math.max(0, tonumber(seconds) or 0)

    local days = math.floor(seconds / 86400)
    seconds = seconds % 86400

    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600

    local minutes = math.floor(seconds / 60)

    if days > 0 then
        return ("%sd %sh"):format(days, hours)
    end

    if hours > 0 then
        return ("%sh %sm"):format(hours, minutes)
    end

    return ("%sm"):format(minutes)
end

----------------------------------------------------------
-- Hotels
----------------------------------------------------------

function Hotel.Shared.GetHotel(hotelId)
    return Config.GetHotel(hotelId)
end

function Hotel.Shared.GetRoom(hotelId, roomId)
    local rooms = Config.Rooms[hotelId]

    if not rooms then
        return nil
    end

    roomId = tonumber(roomId)

    for _, room in pairs(rooms) do
        if tonumber(room.id) == roomId then
            return room
        end
    end

    return nil
end

----------------------------------------------------------
-- Room Status
----------------------------------------------------------

function Hotel.Shared.IsLuxury(room)
    return (room.price or 0) >= (Config.LuxuryPrice or 1000)
end

function Hotel.Shared.IsSuite(room)
    return room.type == "suite"
end

----------------------------------------------------------
-- Validation
----------------------------------------------------------

function Hotel.Shared.ValidHotel(hotelId)
    return Hotel.Shared.GetHotel(hotelId) ~= nil
end

function Hotel.Shared.ValidRoom(hotelId, roomId)
    return Hotel.Shared.GetRoom(hotelId, roomId) ~= nil
end

----------------------------------------------------------
-- IDs
----------------------------------------------------------

function Hotel.Shared.StashId(hotelId, roomId)
    return ("hotel_%s_%s"):format(hotelId, roomId)
end

function Hotel.Shared.RoomKeyId(hotelId, roomId)
    return ("%s_%s"):format(hotelId, roomId)
end

----------------------------------------------------------
-- Exports
----------------------------------------------------------

exports("HotelRound", Hotel.Shared.Round)
exports("HotelClamp", Hotel.Shared.Clamp)
exports("HotelDeepCopy", Hotel.Shared.DeepCopy)
exports("HotelTableCount", Hotel.Shared.TableCount)
exports("HotelEncode", Hotel.Shared.Encode)
exports("HotelDecode", Hotel.Shared.Decode)
exports("HotelFormatMoney", Hotel.Shared.FormatMoney)
exports("HotelGetHotel", Hotel.Shared.GetHotel)
exports("HotelGetRoom", Hotel.Shared.GetRoom)
exports("HotelValidHotel", Hotel.Shared.ValidHotel)
exports("HotelValidRoom", Hotel.Shared.ValidRoom)
exports("HotelStashId", Hotel.Shared.StashId)
exports("HotelRoomKeyId", Hotel.Shared.RoomKeyId)
