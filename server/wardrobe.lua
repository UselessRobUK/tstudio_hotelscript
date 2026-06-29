local Wardrobe = require "bridge.wardrobe"

local function Main() return require "server.main" end

RegisterNetEvent("hotel:openWardrobe", function(hotelId, roomId)
    local src = source
    if not exports[GetCurrentResourceName()]:HasRoomAccess(src, hotelId, tonumber(roomId)) then
        return Main().Notify(src, "You don't have access to this room.", "error")
    end
    TriggerClientEvent("hotel:wardrobeApproved", src, hotelId, tonumber(roomId))
end)

RegisterNetEvent("hotel:saveOutfit", function(name, skin)
    local src        = source
    local identifier = Main().GetIdentifier(src)
    if not identifier then return end
    MySQL.insert.await(
        "INSERT INTO hotel_outfits (identifier, name, skin) VALUES (?, ?, ?)",
        { identifier, name, json.encode(skin) }
    )
    Main().Notify(src, "Outfit saved.", "success")
end)

RegisterNetEvent("hotel:getOutfits", function()
    local src        = source
    local identifier = Main().GetIdentifier(src)
    if not identifier then return end
    local outfits = MySQL.query.await("SELECT * FROM hotel_outfits WHERE identifier = ?", { identifier }) or {}
    TriggerClientEvent("hotel:receiveOutfits", src, outfits)
end)

RegisterNetEvent("hotel:deleteOutfit", function(id)
    local src        = source
    local identifier = Main().GetIdentifier(src)
    if not identifier then return end
    MySQL.query.await("DELETE FROM hotel_outfits WHERE id = ? AND identifier = ?", { id, identifier })
    Main().Notify(src, "Outfit deleted.", "success")
end)

exports("GetWardrobeType", function() return Wardrobe.type end)
