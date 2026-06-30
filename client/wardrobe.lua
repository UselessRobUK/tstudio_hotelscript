local Notify = require "client.notifications"

local wardrobeType = "standalone"

if GetResourceState("illenium-appearance") == "started" then
    wardrobeType = "illenium"
elseif GetResourceState("fivem-appearance") == "started" then
    wardrobeType = "fivem"
elseif GetResourceState("qb-clothing") == "started" then
    wardrobeType = "qb"
elseif GetResourceState("esx_skin") == "started" then
    wardrobeType = "esx"
elseif GetResourceState("rcore_clothing") == "started" then
    wardrobeType = "rcore"
end

local function Open()
    if wardrobeType == "illenium" then TriggerEvent("illenium-appearance:client:openOutfitMenu") return end
    if wardrobeType == "fivem"    then TriggerEvent("fivem-appearance:client:openOutfitMenu")   return end
    if wardrobeType == "qb"       then TriggerEvent("qb-clothing:client:openOutfitMenu")         return end
    if wardrobeType == "esx"      then TriggerEvent("esx_skin:openSaveableMenu")                 return end
    if wardrobeType == "rcore"    then TriggerEvent("rcore_clothing:openWardrobe")               return end
    Notify.Info("No wardrobe resource detected.")
end

-- access already validated by client/rooms.lua before this event fires
RegisterNetEvent("hotel:wardrobeOpen", function()
    Open()
end)

RegisterCommand("hotelwardrobe", function()
    Open()
end)

exports("OpenWardrobe", Open)
