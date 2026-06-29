local Config = require "configs.shared.main"
local Hotels = require "configs.shared.hotels"
local Rooms  = require "configs.shared.rooms"

---@param value number
---@param decimals? number
---@return number
local function Round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor((tonumber(value) or 0) * mult + 0.5) / mult
end

---@param value number
---@param min number
---@param max number
---@return number
local function Clamp(value, min, max)
    value = tonumber(value) or 0
    if value < min then return min end
    if value > max then return max end
    return value
end

---@param tbl table
---@return table
local function DeepCopy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do copy[k] = DeepCopy(v) end
    return copy
end

---@param tbl table
---@return number
local function TableCount(tbl)
    local count = 0
    for _ in pairs(tbl or {}) do count = count + 1 end
    return count
end

---@param data any
---@return string
local function Encode(data)
    local ok, encoded = pcall(json.encode, data)
    return ok and encoded or "{}"
end

---@param data string
---@return any
local function Decode(data)
    if not data or data == "" then return nil end
    local ok, decoded = pcall(json.decode, data)
    return ok and decoded or nil
end

---@param amount number
---@return string
local function FormatMoney(amount)
    return ("%s%s"):format(Config.Currency or "£", tonumber(amount) or 0)
end

---@param text string
---@return string
local function Trim(text)
    return tostring(text):match("^%s*(.-)%s*$")
end

---@return number
local function Timestamp()
    return os.time()
end

---@param seconds number
---@return string
local function FormatTime(seconds)
    seconds = math.max(0, tonumber(seconds) or 0)
    local days    = math.floor(seconds / 86400)
    seconds = seconds % 86400
    local hours   = math.floor(seconds / 3600)
    seconds = seconds % 3600
    local minutes = math.floor(seconds / 60)
    if days > 0   then return ("%sd %sh"):format(days, hours) end
    if hours > 0  then return ("%sh %sm"):format(hours, minutes) end
    return ("%sm"):format(minutes)
end

---@param hotelId string
---@return table|nil
local function GetHotel(hotelId)
    for _, hotel in pairs(Hotels) do
        if hotel.id == hotelId then return hotel end
    end
    return nil
end

---@param hotelId string
---@param roomId number
---@return table|nil
local function GetRoom(hotelId, roomId)
    local hotel = GetHotel(hotelId)
    if hotel and hotel.rooms then
        roomId = tonumber(roomId)
        for _, room in pairs(hotel.rooms) do
            if tonumber(room.id) == roomId then return room end
        end
    end
    local hotelRooms = Rooms[hotelId]
    if hotelRooms then
        roomId = tonumber(roomId)
        for _, room in pairs(hotelRooms) do
            if tonumber(room.id) == roomId then return room end
        end
    end
    return nil
end

---@param hotelId string
---@param roomId number
---@return string
local function StashId(hotelId, roomId)
    return ("hotel_%s_%s"):format(hotelId, roomId)
end

---@param hotelId string
---@param roomId number
---@return string
local function RoomKeyId(hotelId, roomId)
    return ("%s_%s"):format(hotelId, roomId)
end

return {
    Round       = Round,
    Clamp       = Clamp,
    DeepCopy    = DeepCopy,
    TableCount  = TableCount,
    Encode      = Encode,
    Decode      = Decode,
    FormatMoney = FormatMoney,
    Trim        = Trim,
    Timestamp   = Timestamp,
    FormatTime  = FormatTime,
    GetHotel    = GetHotel,
    GetRoom     = GetRoom,
    StashId     = StashId,
    RoomKeyId   = RoomKeyId,
}
