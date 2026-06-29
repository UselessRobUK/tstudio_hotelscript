--========================================================--
-- Standalone Hotel Framework
-- server/bindings.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Bindings = {}

----------------------------------------------------------
-- Resource Detection
----------------------------------------------------------

local HasOxDoorlock = GetResourceState("ox_doorlock") == "started"
local HasOxInventory = GetResourceState("ox_inventory") == "started"

----------------------------------------------------------
-- Door Registration
----------------------------------------------------------

function Hotel.Bindings.RegisterDoor(hotelId, room)

    if not HasOxDoorlock then
        return false
    end

    if not room.door then
        return false
    end

    local id = ("hotel_%s_%s"):format(hotelId, room.id)

    exports.ox_doorlock:addDoor({

        id = id,

        coords = room.door.coords,

        heading = room.door.heading,

        locked = true,

        distance = 2.0,

        groups = {},

        state = 1

    })

    return true

end

----------------------------------------------------------
-- Register Inventory Stash
----------------------------------------------------------

function Hotel.Bindings.RegisterStash(hotelId, room)

    if not HasOxInventory then
        return false
    end

    if not room.stash then
        return false
    end

    exports.ox_inventory:RegisterStash(

        ("hotel_%s_%s"):format(hotelId, room.id),

        room.label or ("Room "..room.id),

        Config.StashSlots or 30,

        Config.StashWeight or 50000,

        false

    )

    return true

end

----------------------------------------------------------
-- Register Wardrobe
----------------------------------------------------------

function Hotel.Bindings.RegisterWardrobe(hotelId, room)

    if not room.wardrobe then
        return false
    end

    return true

end

----------------------------------------------------------
-- Register Room
----------------------------------------------------------

function Hotel.Bindings.RegisterRoom(hotelId, room)

    Hotel.Bindings.RegisterDoor(hotelId, room)

    Hotel.Bindings.RegisterStash(hotelId, room)

    Hotel.Bindings.RegisterWardrobe(hotelId, room)

end

----------------------------------------------------------
-- Register Hotel
----------------------------------------------------------

function Hotel.Bindings.RegisterHotel(hotel)

    if not hotel.rooms then
        return
    end

    for _, room in pairs(hotel.rooms) do

        Hotel.Bindings.RegisterRoom(
            hotel.id,
            room
        )

    end

end

----------------------------------------------------------
-- Register All Hotels
----------------------------------------------------------

CreateThread(function()

    Wait(2000)

    for _, hotel in pairs(Config.Hotels or {}) do

        Hotel.Bindings.RegisterHotel(hotel)

    end

    print("^2[HOTEL]^7 Resource bindings loaded.")

end)

----------------------------------------------------------
-- Runtime Registration
----------------------------------------------------------

RegisterNetEvent("hotel:registerBindings", function(hotelId)

    local hotel = Hotel.GetHotel(hotelId)

    if not hotel then
        return
    end

    Hotel.Bindings.RegisterHotel(hotel)

end)

----------------------------------------------------------
-- Exports
----------------------------------------------------------

exports("RegisterHotelBindings", Hotel.Bindings.RegisterHotel)

exports("RegisterRoomBindings", Hotel.Bindings.RegisterRoom)
