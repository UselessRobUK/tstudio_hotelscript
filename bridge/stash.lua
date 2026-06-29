local Config = require "configs.shared.main"

local type = "standalone"

if GetResourceState("ox_inventory") == "started" then
    type = "ox"
elseif GetResourceState("qb-inventory") == "started" then
    type = "qb"
elseif GetResourceState("qs-inventory") == "started" then
    type = "qs"
end

---@param hotelId string
---@param roomId number
---@return string
local function GetId(hotelId, roomId)
    return ("hotel_%s_%s"):format(hotelId, tonumber(roomId))
end

---@param hotelId string
---@param room table
---@return boolean
local function Register(hotelId, room)
    local stashId = GetId(hotelId, room.id)
    local label   = room.label or ("Hotel Room %s"):format(room.id)
    local slots   = room.stashSlots or Config.StashSlots or 30
    local weight  = room.stashWeight or Config.StashWeight or 50000

    if type == "ox" then
        exports.ox_inventory:RegisterStash(stashId, label, slots, weight, false)
    end

    return true
end

---@param src number
---@param hotelId string
---@param roomId number
---@return boolean
local function Open(src, hotelId, roomId)
    TriggerClientEvent("hotel:stashApproved", src, hotelId, tonumber(roomId))
    return true
end

---@param hotels table
---@param rooms table
local function RegisterAll(hotels, rooms)
    for _, hotel in pairs(hotels or {}) do
        local hotelRooms = hotel.rooms or (rooms and rooms[hotel.id]) or {}
        for _, room in pairs(hotelRooms) do
            if room.stash then
                Register(hotel.id, room)
            end
        end
    end
end

return {
    type        = type,
    GetId       = GetId,
    Register    = Register,
    Open        = Open,
    RegisterAll = RegisterAll,
}
