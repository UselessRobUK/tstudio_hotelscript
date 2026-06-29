--========================================================--
-- Standalone Hotel Framework
-- bridge/inventory.lua
--========================================================--

Bridge = Bridge or {}
Bridge.Inventory = Bridge.Inventory or {}

Bridge.Inventory.Type = "standalone"

if GetResourceState("ox_inventory") == "started" then
    Bridge.Inventory.Type = "ox"
elseif GetResourceState("qb-inventory") == "started" then
    Bridge.Inventory.Type = "qb"
elseif GetResourceState("qs-inventory") == "started" then
    Bridge.Inventory.Type = "qs"
elseif GetResourceState("lj-inventory") == "started" then
    Bridge.Inventory.Type = "lj"
end

function Bridge.Inventory.AddItem(src, item, count, metadata)
    count = tonumber(count) or 1
    metadata = metadata or {}

    if Bridge.Inventory.Type == "ox" then
        return exports.ox_inventory:AddItem(src, item, count, metadata)
    end

    if Bridge.Inventory.Type == "qb" or Bridge.Inventory.Type == "lj" then
        local QBCore = exports["qb-core"]:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return false end
        return Player.Functions.AddItem(item, count, false, metadata)
    end

    if Bridge.Inventory.Type == "qs" then
        return exports["qs-inventory"]:AddItem(src, item, count, nil, metadata)
    end

    return true
end

function Bridge.Inventory.RemoveItem(src, item, count, metadata)
    count = tonumber(count) or 1
    metadata = metadata or {}

    if Bridge.Inventory.Type == "ox" then
        return exports.ox_inventory:RemoveItem(src, item, count, metadata)
    end

    if Bridge.Inventory.Type == "qb" or Bridge.Inventory.Type == "lj" then
        local QBCore = exports["qb-core"]:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return false end
        return Player.Functions.RemoveItem(item, count)
    end

    if Bridge.Inventory.Type == "qs" then
        return exports["qs-inventory"]:RemoveItem(src, item, count)
    end

    return true
end

function Bridge.Inventory.HasItem(src, item, metadata)
    metadata = metadata or {}

    if Bridge.Inventory.Type == "ox" then
        local count = exports.ox_inventory:Search(src, "count", item, metadata)
        return (count or 0) > 0
    end

    if Bridge.Inventory.Type == "qb" or Bridge.Inventory.Type == "lj" then
        local QBCore = exports["qb-core"]:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return false end
        return Player.Functions.GetItemByName(item) ~= nil
    end

    if Bridge.Inventory.Type == "qs" then
        local count = exports["qs-inventory"]:GetItemTotalAmount(src, item)
        return (count or 0) > 0
    end

    return true
end

function Bridge.Inventory.GiveHotelKey(src, hotelId, roomId, expires)
    if Config.UsePhysicalKeys == false then
        return true
    end

    return Bridge.Inventory.AddItem(
        src,
        Config.KeyItem or "hotel_key",
        1,
        {
            hotel = hotelId,
            room = tonumber(roomId),
            expires = tonumber(expires),
            label = ("Hotel Key - Room %s"):format(roomId)
        }
    )
end

function Bridge.Inventory.RemoveHotelKey(src, hotelId, roomId)
    if Config.UsePhysicalKeys == false then
        return true
    end

    return Bridge.Inventory.RemoveItem(
        src,
        Config.KeyItem or "hotel_key",
        1,
        {
            hotel = hotelId,
            room = tonumber(roomId)
        }
    )
end

exports("InventoryType", function()
    return Bridge.Inventory.Type
end)

exports("InventoryAddItem", Bridge.Inventory.AddItem)
exports("InventoryRemoveItem", Bridge.Inventory.RemoveItem)
exports("InventoryHasItem", Bridge.Inventory.HasItem)
exports("InventoryGiveHotelKey", Bridge.Inventory.GiveHotelKey)
exports("InventoryRemoveHotelKey", Bridge.Inventory.RemoveHotelKey)
