local Config = require "configs.shared.main"
local Hotels = require "configs.shared.hotels"

local Zones = {
    active       = {},
    currentHotel = nil,
    currentRoom  = nil,
}

local function DrawText3D(coords, text)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

local function IsNear(coords, target, distance)
    return #(coords - vector3(target.x, target.y, target.z)) <= distance
end

CreateThread(function()
    while true do
        local sleep  = 1000
        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for _, hotel in pairs(Hotels) do
            if hotel.entrance and IsNear(coords, hotel.entrance, 2.0) then
                sleep = 0
                Zones.currentHotel = hotel.id

                DrawText3D(
                    vector3(hotel.entrance.x, hotel.entrance.y, hotel.entrance.z + 0.3),
                    "[E] Open Hotel"
                )

                if IsControlJustReleased(0, Config.InteractKey or 38) then                    TriggerEvent("hotel:openMenu", hotel.id)
                end
            end

            if hotel.boss and IsNear(coords, hotel.boss, 2.0) then
                sleep = 0

                DrawText3D(
                    vector3(hotel.boss.x, hotel.boss.y, hotel.boss.z + 0.3),
                    "[E] Hotel Management"
                )

                if IsControlJustReleased(0, Config.InteractKey or 38) then                    TriggerEvent("hotel:openBossMenu", hotel.id)
                end
            end

            if hotel.rooms then
                for _, room in pairs(hotel.rooms) do

                    if room.entrance and IsNear(coords, room.entrance.coords or room.entrance, 2.0) then
                        sleep = 0
                        Zones.currentHotel = hotel.id
                        Zones.currentRoom = room.id

                        local point = room.entrance.coords or room.entrance

                        DrawText3D(
                            vector3(point.x, point.y, point.z + 0.3),
                            ("[E] Enter %s"):format(room.label or ("Room " .. room.id))
                        )

                        if IsControlJustReleased(0, Config.InteractKey or 38) then                            TriggerEvent("hotel:enterRoom", hotel.id, room.id)
                        end
                    end

                    if room.stash and IsNear(coords, room.stash, 1.5) then
                        sleep = 0

                        DrawText3D(
                            vector3(room.stash.x, room.stash.y, room.stash.z + 0.2),
                            "[E] Open Stash"
                        )

                        if IsControlJustReleased(0, Config.InteractKey or 38) then                            TriggerEvent("hotel:openStash", hotel.id, room.id)
                        end
                    end

                    if room.wardrobe and IsNear(coords, room.wardrobe, 1.5) then
                        sleep = 0

                        DrawText3D(
                            vector3(room.wardrobe.x, room.wardrobe.y, room.wardrobe.z + 0.2),
                            "[E] Wardrobe"
                        )

                        if IsControlJustReleased(0, Config.InteractKey or 38) then                            TriggerEvent("hotel:openWardrobe", hotel.id, room.id)
                        end
                    end

                    if room.exit and IsNear(coords, room.exit, 1.5) then
                        sleep = 0

                        DrawText3D(
                            vector3(room.exit.x, room.exit.y, room.exit.z + 0.2),
                            "[E] Exit Room"
                        )

                        if IsControlJustReleased(0, Config.InteractKey or 38) then                            TriggerEvent("hotel:exitRoom", hotel.id, room.id)
                        end
                    end

                end
            end
        end

        Wait(sleep)
    end
end)

RegisterNetEvent("hotel:setCurrentZone", function(hotelId, roomId)
    Zones.currentHotel = hotelId
    Zones.currentRoom = roomId
end)

exports("GetCurrentHotelZone", function()
    return {
        hotel = Zones.currentHotel,
        room = Zones.currentRoom
    }
end)

exports("IsInHotelZone", function()
    return Zones.currentHotel ~= nil
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    Zones.active = {}
    Zones.currentHotel = nil
    Zones.currentRoom = nil
end)
