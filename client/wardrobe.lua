--========================================================--
-- Standalone Hotel Framework
-- client/wardrobe.lua
--========================================================--

local Wardrobe = {}

----------------------------------------------------------
-- Resource Detection
----------------------------------------------------------

Wardrobe.Type = "standalone"

if GetResourceState("illenium-appearance") == "started" then
    Wardrobe.Type = "illenium"

elseif GetResourceState("fivem-appearance") == "started" then
    Wardrobe.Type = "fivem"

elseif GetResourceState("qb-clothing") == "started" then
    Wardrobe.Type = "qb"

elseif GetResourceState("esx_skin") == "started" then
    Wardrobe.Type = "esx"

elseif GetResourceState("rcore_clothing") == "started" then
    Wardrobe.Type = "rcore"
end

----------------------------------------------------------
-- Notification
----------------------------------------------------------

local function Notify(msg)

    TriggerEvent("hotel:notify", msg)

end

----------------------------------------------------------
-- Open Wardrobe
----------------------------------------------------------

function Wardrobe.Open()

    if Wardrobe.Type == "illenium" then

        TriggerEvent("illenium-appearance:client:openOutfitMenu")

        return

    end

    if Wardrobe.Type == "fivem" then

        TriggerEvent("fivem-appearance:client:openOutfitMenu")

        return

    end

    if Wardrobe.Type == "qb" then

        TriggerEvent("qb-clothing:client:openOutfitMenu")

        return

    end

    if Wardrobe.Type == "esx" then

        TriggerEvent("esx_skin:openSaveableMenu")

        return

    end

    if Wardrobe.Type == "rcore" then

        TriggerEvent("rcore_clothing:openWardrobe")

        return

    end

    Notify("No wardrobe resource detected.")

end

----------------------------------------------------------
-- Hotel Event
----------------------------------------------------------

RegisterNetEvent("hotel:wardrobeOpen", function(hotelId, roomId)

    if exports["hotel-system"]:IsInsideHotelRoom() then

        Wardrobe.Open()

    else

        TriggerServerEvent(
            "hotel:checkRoomAccess",
            hotelId,
            roomId,
            "wardrobe"
        )

    end

end)

----------------------------------------------------------
-- Server Approved
----------------------------------------------------------

RegisterNetEvent("hotel:wardrobeApproved", function()

    Wardrobe.Open()

end)

----------------------------------------------------------
-- Debug Command
----------------------------------------------------------

RegisterCommand("hotelwardrobe", function()

    Wardrobe.Open()

end)

----------------------------------------------------------
-- Export
----------------------------------------------------------

exports("OpenWardrobe", function()

    Wardrobe.Open()

end)
