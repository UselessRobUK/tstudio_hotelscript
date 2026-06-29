-- Server-side inventory operations delegate to bridge/inventory
local Inventory = require "bridge.inventory"

exports("InventoryAddItem",        Inventory.AddItem)
exports("InventoryRemoveItem",     Inventory.RemoveItem)
exports("InventoryHasItem",        Inventory.HasItem)
exports("InventoryGiveHotelKey",   Inventory.GiveHotelKey)
exports("InventoryRemoveHotelKey", Inventory.RemoveHotelKey)
