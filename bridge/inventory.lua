local Config = require "configs.shared.main"

local type = "standalone"

if GetResourceState("ox_inventory") == "started" then
    type = "ox"
elseif GetResourceState("qb-inventory") == "started" then
    type = "qb"
elseif GetResourceState("qs-inventory") == "started" then
    type = "qs"
elseif GetResourceState("lj-inventory") == "started" then
    type = "lj"
end

---@param src number
---@param item string
---@param count number
---@param metadata? table
---@return boolean
local function AddItem(src, item, count, metadata)
    count    = tonumber(count) or 1
    metadata = metadata or {}

    if type == "ox" then
        return exports.ox_inventory:AddItem(src, item, count, metadata)
    end

    if type == "qb" or type == "lj" then
        local QBCore = exports["qb-core"]:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return false end
        return Player.Functions.AddItem(item, count, false, metadata)
    end

    if type == "qs" then
        return exports["qs-inventory"]:AddItem(src, item, count, nil, metadata)
    end

    return true
end

---@param src number
---@param item string
---@param count number
---@param metadata? table
---@return boolean
local function RemoveItem(src, item, count, metadata)
    count    = tonumber(count) or 1
    metadata = metadata or {}

    if type == "ox" then
        return exports.ox_inventory:RemoveItem(src, item, count, metadata)
    end

    if type == "qb" or type == "lj" then
        local QBCore = exports["qb-core"]:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return false end
        return Player.Functions.RemoveItem(item, count)
    end

    if type == "qs" then
        return exports["qs-inventory"]:RemoveItem(src, item, count)
    end

    return true
end

---@param src number
---@param item string
---@param metadata? table
---@return boolean
local function HasItem(src, item, metadata)
    metadata = metadata or {}

    if type == "ox" then
        local count = exports.ox_inventory:Search(src, "count", item, metadata)
        return (count or 0) > 0
    end

    if type == "qb" or type == "lj" then
        local QBCore = exports["qb-core"]:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return false end
        return Player.Functions.GetItemByName(item) ~= nil
    end

    if type == "qs" then
        local count = exports["qs-inventory"]:GetItemTotalAmount(src, item)
        return (count or 0) > 0
    end

    return true
end

---@param src number
---@param item string
---@return number
local function GetItemCount(src, item)
    if type == "ox" then
        return exports.ox_inventory:Search(src, "count", item) or 0
    end

    if type == "qb" or type == "lj" then
        local QBCore = exports["qb-core"]:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return 0 end
        local itemData = Player.Functions.GetItemByName(item)
        return itemData and itemData.amount or 0
    end

    if type == "qs" then
        return exports["qs-inventory"]:GetItemTotalAmount(src, item) or 0
    end

    return 0
end

---@param src number
---@param hotelId string
---@param roomId number
---@param expires number
---@return boolean
local function GiveHotelKey(src, hotelId, roomId, expires)
    if not Config.UsePhysicalKeys then return true end
    return AddItem(src, Config.KeyItem or "hotel_key", 1, {
        hotel   = hotelId,
        room    = tonumber(roomId),
        expires = tonumber(expires),
        label   = ("Hotel Key - Room %s"):format(roomId),
    })
end

---@param src number
---@param hotelId string
---@param roomId number
---@return boolean
local function RemoveHotelKey(src, hotelId, roomId)
    if not Config.UsePhysicalKeys then return true end
    return RemoveItem(src, Config.KeyItem or "hotel_key", 1, {
        hotel = hotelId,
        room  = tonumber(roomId),
    })
end

return {
    type           = type,
    AddItem        = AddItem,
    RemoveItem     = RemoveItem,
    HasItem        = HasItem,
    GetItemCount   = GetItemCount,
    GiveHotelKey   = GiveHotelKey,
    RemoveHotelKey = RemoveHotelKey,
}
