--========================================================--
-- Standalone Hotel Framework
-- bridge/wardrobe.lua
--========================================================--

Bridge = Bridge or {}
Bridge.Wardrobe = Bridge.Wardrobe or {}

Bridge.Wardrobe.Type = "standalone"

if GetResourceState("illenium-appearance") == "started" then
    Bridge.Wardrobe.Type = "illenium"
elseif GetResourceState("fivem-appearance") == "started" then
    Bridge.Wardrobe.Type = "fivem"
elseif GetResourceState("qb-clothing") == "started" then
    Bridge.Wardrobe.Type = "qb"
elseif GetResourceState("esx_skin") == "started" then
    Bridge.Wardrobe.Type = "esx"
elseif GetResourceState("rcore_clothing") == "started" then
    Bridge.Wardrobe.Type = "rcore"
end

function Bridge.Wardrobe.Open(src)
    TriggerClientEvent("hotel:wardrobeApproved", src)
    return true
end

function Bridge.Wardrobe.GetType()
    return Bridge.Wardrobe.Type
end

exports("WardrobeOpen", Bridge.Wardrobe.Open)
exports("WardrobeType", Bridge.Wardrobe.GetType)
