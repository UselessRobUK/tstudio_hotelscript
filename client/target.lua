--========================================================--
-- Standalone Hotel System
-- client/target.lua
--========================================================--

local UsingOxTarget = GetResourceState("ox_target") == "started"
local UsingQBTarget = GetResourceState("qb-target") == "started"

local RegisteredZones = {}

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function AddTargetZone(data)
    if UsingOxTarget then
        return exports.ox_target:addBoxZone(data)
    end

    if UsingQBTarget then
        return exports['qb-target']:AddBoxZone(
            data.name,
            data.coords,
            data.size.x,
            data.size.y,
            {
                name = data.name,
                heading = data.heading or 0.0,
                debugPoly = false,
                minZ = data.minZ,
                maxZ = data.maxZ
            },
            {
                options = data.options,
                distance = data.distance or 2.0
            }
        )
    end

    return nil
end

local function RemoveZone(id)
    if UsingOxTarget then
        exports.ox_target:removeZone(id)
    elseif UsingQBTarget then
        exports['qb-target']:RemoveZone(id)
    end
end

--------------------------------------------------
-- HOTEL NPC INTERACTION
--------------------------------------------------

function RegisterHotelNPC(hotel)
    if not hotel or not hotel.reception then return end

    local zone = {
        name = "hotel_npc_" .. hotel.id,

        coords = vector3(
            hotel.reception.coords.x,
            hotel.reception.coords.y,
            hotel.reception.coords.z
        ),

        size = vec3(1.5, 1.5, 2.0),

        heading = hotel.reception.coords.w,

        debug = false,

        options = {
            {
                name = "hotel_open_" .. hotel.id,
                icon = "fa-solid fa-hotel",
                label = "Speak to Reception",

                onSelect = function()
                    TriggerEvent("hotel:openMenu", hotel.id)
                end
            }
        }
    }

    local zoneId = AddTargetZone(zone)

    RegisteredZones["npc_" .. hotel.id] = zoneId
end

--------------------------------------------------
-- ROOM STASH INTERACTION
--------------------------------------------------

function RegisterRoomStash(hotelId, room)
    local zone = {
        name = "hotel_stash_" .. hotelId .. "_" .. room.id,

        coords = room.stash,

        size = vec3(1.0, 1.0, 1.0),

        options = {
            {
                name = "open_stash_" .. room.id,
                icon = "fa-solid fa-box",
                label = "Open Room Stash",

                onSelect = function()
                    TriggerEvent("hotel:openStash", hotelId, room.id)
                end
            }
        }
    }

    local zoneId = AddTargetZone(zone)

    RegisteredZones["stash_" .. hotelId .. "_" .. room.id] = zoneId
end

------------------------------------------------
