--========================================================--
-- Standalone Hotel Framework
-- server/wardrobe.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Wardrobe = Hotel.Wardrobe or {}

----------------------------------------------------------
-- Detect Wardrobe Resource
----------------------------------------------------------

Hotel.Wardrobe.Type = "standalone"

if GetResourceState("illenium-appearance") == "started" then
    Hotel.Wardrobe.Type = "illenium"

elseif GetResourceState("fivem-appearance") == "started" then
    Hotel.Wardrobe.Type = "fivem"

elseif GetResourceState("qb-clothing") == "started" then
    Hotel.Wardrobe.Type = "qb"

elseif GetResourceState("esx_skin") == "started" then
    Hotel.Wardrobe.Type = "esx"

elseif GetResourceState("rcore_clothing") == "started" then
    Hotel.Wardrobe.Type = "rcore"

end

----------------------------------------------------------
-- Open Wardrobe
----------------------------------------------------------

RegisterNetEvent("hotel:openWardrobe", function(hotelId, roomId)

    local src = source

    if not exports[GetCurrentResourceName()]:HasRoomAccess(
        src,
        hotelId,
        tonumber(roomId)
    ) then

        return Hotel.Notify(
            src,
            "You don't have access to this room.",
            "error"
        )

    end

    TriggerClientEvent(
        "hotel:wardrobeApproved",
        src,
        hotelId,
        tonumber(roomId)
    )

end)

----------------------------------------------------------
-- Outfit Save Callback
----------------------------------------------------------

RegisterNetEvent("hotel:saveOutfit", function(name, skin)

    local src = source

    local identifier = Hotel.GetIdentifier(src)

    if not identifier then return end

    if MySQL then

        MySQL.insert.await([[
            INSERT INTO hotel_outfits
            (identifier,name,skin)
            VALUES (?,?,?)
        ]],{

            identifier,

            name,

            json.encode(skin)

        })

    end

    Hotel.Notify(
        src,
        "Outfit saved.",
        "success"
    )

end)

----------------------------------------------------------
-- Get Outfits
----------------------------------------------------------

RegisterNetEvent("hotel:getOutfits", function()

    local src = source

    local identifier = Hotel.GetIdentifier(src)

    if not identifier then return end

    local outfits = {}

    if MySQL then

        outfits = MySQL.query.await(

            "SELECT * FROM hotel_outfits WHERE identifier=?",

            {identifier}

        ) or {}

    end

    TriggerClientEvent(
        "hotel:receiveOutfits",
        src,
        outfits
    )

end)

----------------------------------------------------------
-- Delete Outfit
----------------------------------------------------------

RegisterNetEvent("hotel:deleteOutfit", function(id)

    local src = source

    local identifier = Hotel.GetIdentifier(src)

    if not identifier then return end

    if MySQL then

        MySQL.query.await(

            "DELETE FROM hotel_outfits WHERE id=? AND identifier=?",

            {id,identifier}

        )

    end

    Hotel.Notify(
        src,
        "Outfit deleted.",
        "success"
    )

end)

----------------------------------------------------------
-- Exports
----------------------------------------------------------

exports("GetWardrobeType", function()

    return Hotel.Wardrobe.Type

end)
