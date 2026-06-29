--========================================================--
-- Standalone Hotel Framework
-- server/inventory.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Inventory = Hotel.Inventory or {}

Hotel.Inventory.Type = "standalone"

if GetResourceState("ox_inventory") == "started" then
    Hotel.Inventory.Type = "ox"
elseif GetResourceState("qb-inventory") == "started" then
    Hotel.Inventory.Type = "qb"
elseif GetResourceState("qs-inventory") == "started" then
    Hotel.Inventory.Type = "qs"
end

function Hotel.Inventory.AddItem(src, item, count, metadata)
    count = tonumber(count) or 1
    metadata = metadata or {}

    if Hotel.Inventory.Type == "ox" then
        return exports.ox_inventory:AddItem(src, item, count, metadata)
    end

    if Hotel.Inventory.Type == "qb" then
        local Player = exports["qb-core"]:GetCoreObject().Functions.GetPlayer(src)
        if not Player then return false end

        return Player.Functions.AddItem(item, count, false, metadata)
    end

    if Hotel.Inventory.Type == "qs" then
        return exports["qs-inventory"]:AddItem(src, item, count, nil, metadata)
    end

    return true
end

function Hotel.Inventory.RemoveItem(src, item, count, metadata)
    count = tonumber(count) or 1

    if Hotel.Inventory.Type == "ox" then
        return exports.ox_inventory:RemoveItem(src, item, count, metadata)
    end

    if Hotel.Inventory.Type == "qb" then
        local Player = exports["qb-core"]:GetCoreObject().Functions.GetPlayer(src)
        if not Player then return false end

        return Player.Functions.RemoveItem(item, count)
    end

    if Hotel.Inventory.Type == "qs" then
        return exports["qs-inventory"]:RemoveItem(src, item, count)
    end

    return true
end

function Hotel.Inventory.HasItem(src, item, metadata)
    if Hotel.Inventory.Type == "ox" then
        local count = exports.ox_inventory:Search(src, "count", item, metadata)
        return (count or 0) > 0
    end

    if Hotel.Inventory.Type == "qb" then
        local Player = exports["qb-core"]:GetCoreObject().Functions.GetPlayer(src)
        if not Player then return false end

        local found = Player.Functions.GetItemByName(item)
        return found ~= nil
    end

    if Hotel.Inventory.Type == "qs" then
        local count = exports["qs-inventory"]:GetItemTotalAmount(src, item)
        return (count or 0) > 0
    end

    return true
end

function Hotel.Inventory.GiveHotelKey(src, hotelId, roomId, expires)
    local metadata = {
        hotel = hotelId,
        room = tonumber(roomId),
        expires = tonumber(expires),
        label = ("Hotel Key - Room %s"):format(roomId)
    }

    if Config.UsePhysicalKeys == false then
        return true
    end

    return Hotel.Inventory.AddItem(
        src,
        Config.KeyItem or "hotel_key",
        1,
        metadata
    )
end

function Hotel.Inventory.RemoveHotelKey(src, hotelId, roomId)
    if Config.UsePhysicalKeys == false then
        return true
    end

    return Hotel.Inventory.RemoveItem(
        src,
        Config.KeyItem or "hotel_key",
        1,
        {
            hotel = hotelId,
            room = tonumber(roomId)
        }
    )
end

exports("InventoryAddItem", Hotel.Inventory.AddItem)
exports("InventoryRemoveItem", Hotel.Inventory.RemoveItem)
exports("InventoryHasItem", Hotel.Inventory.HasItem)
exports("InventoryGiveHotelKey", Hotel.Inventory.GiveHotelKey)
exports("InventoryRemoveHotelKey", Hotel.Inventory.RemoveHotelKey)
