--========================================================--
-- Hotel Builder
-- Standalone Hotel Framework
-- client/builder.lua
--========================================================--

local Builder = {
    enabled = false,
    hotel = {
        name = "New Hotel",
        id = "hotel_01",
        entrance = nil,
        reception = nil,
        rooms = {}
    },
    currentRoom = nil
}

local function Notify(msg)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end

local function Draw3D(x, y, z, text)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

local function GetCoords()
    local ped = PlayerPedId()
    return GetEntityCoords(ped), GetEntityHeading(ped)
end

local function AddRoom()
    local coords, heading = GetCoords()

    local room = {
        id = #Builder.hotel.rooms + 101,
        label = ("Room %s"):format(#Builder.hotel.rooms + 101),

        entrance = {
            coords = coords,
            heading = heading
        },

        stash = nil,
        wardrobe = nil,
        exit = nil,
        price = 250,
        duration = 24
    }

    table.insert(Builder.hotel.rooms, room)

    Builder.currentRoom = #Builder.hotel.rooms

    Notify("Room created.")
end

local builderActive = false

RegisterCommand("hotelbuilder", function()
    Builder.enabled = not Builder.enabled
    Notify("Hotel Builder: "..tostring(Builder.enabled))
    if Builder.enabled and not builderActive then
        builderActive = true
        CreateThread(function()
            while Builder.enabled do
                Wait(0)

                local ped    = PlayerPedId()
                local coords = GetEntityCoords(ped)

                Draw3D(coords.x, coords.y, coords.z + 1.0, [[HOTEL BUILDER

/ hotel_setname
/ hotel_setid
/ hotel_entrance
/ hotel_reception
/ hotel_addroom
/ hotel_roomstash
/ hotel_roomwardrobe
/ hotel_roomexit
/ hotel_roomprice
/ hotel_save
]])

                if Builder.hotel.entrance then
                    DrawMarker(1,
                        Builder.hotel.entrance.coords.x,
                        Builder.hotel.entrance.coords.y,
                        Builder.hotel.entrance.coords.z - 1.0,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0,
                        0, 255, 0, 150, false, true, 2)
                end

                for _, room in ipairs(Builder.hotel.rooms) do
                    DrawMarker(2,
                        room.entrance.coords.x,
                        room.entrance.coords.y,
                        room.entrance.coords.z,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5,
                        255, 255, 0, 180, false, true, 2)
                    Draw3D(
                        room.entrance.coords.x,
                        room.entrance.coords.y,
                        room.entrance.coords.z + 0.5,
                        room.label
                    )
                end
            end
            builderActive = false
        end)
    end
end)

RegisterCommand("hotel_setname", function(_, args)

    Builder.hotel.name = table.concat(args, " ")

    Notify("Hotel Name Updated")

end)

RegisterCommand("hotel_setid", function(_, args)

    Builder.hotel.id = args[1]

    Notify("Hotel ID Updated")

end)

RegisterCommand("hotel_entrance", function()

    local coords, heading = GetCoords()

    Builder.hotel.entrance = {
        coords = coords,
        heading = heading
    }

    Notify("Entrance Saved")

end)

RegisterCommand("hotel_reception", function()

    local coords, heading = GetCoords()

    Builder.hotel.reception = {
        model = "s_m_m_highsec_01",
        coords = coords,
        heading = heading
    }

    Notify("Reception Saved")

end)

RegisterCommand("hotel_addroom", function()

    AddRoom()

end)

RegisterCommand("hotel_roomprice", function(_, args)

    if not Builder.currentRoom then return end

    Builder.hotel.rooms[Builder.currentRoom].price =
        tonumber(args[1]) or 250

end)

RegisterCommand("hotel_roomstash", function()

    if not Builder.currentRoom then return end

    local coords = GetEntityCoords(PlayerPedId())

    Builder.hotel.rooms[Builder.currentRoom].stash = coords

    Notify("Stash Saved")

end)

RegisterCommand("hotel_roomwardrobe", function()

    if not Builder.currentRoom then return end

    local coords = GetEntityCoords(PlayerPedId())

    Builder.hotel.rooms[Builder.currentRoom].wardrobe = coords

    Notify("Wardrobe Saved")

end)

RegisterCommand("hotel_roomexit", function()

    if not Builder.currentRoom then return end

    local coords = GetEntityCoords(PlayerPedId())

    Builder.hotel.rooms[Builder.currentRoom].exit = coords

    Notify("Exit Saved")

end)

RegisterCommand("hotel_save", function()

    TriggerServerEvent("hotel:saveLayout", Builder.hotel)

end)

RegisterCommand("hotel_clear", function()

    Builder.hotel = {

        id = "hotel_01",

        name = "New Hotel",

        entrance = nil,

        reception = nil,

        rooms = {}

    }

    Builder.currentRoom = nil

end)

