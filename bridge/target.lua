--========================================================--
-- Standalone Hotel Framework
-- bridge/target.lua
--========================================================--

Bridge = Bridge or {}
Bridge.Target = Bridge.Target or {}

----------------------------------------------------------
-- Detect Target System
----------------------------------------------------------

Bridge.Target.Type = "standalone"

if GetResourceState("ox_target") == "started" then
    Bridge.Target.Type = "ox"

elseif GetResourceState("qb-target") == "started" then
    Bridge.Target.Type = "qb"

elseif GetResourceState("interact") == "started" then
    Bridge.Target.Type = "interact"

end

----------------------------------------------------------
-- Add Box Zone
----------------------------------------------------------

function Bridge.Target.AddBoxZone(id, coords, size, options)

    size = size or vec3(1.0, 1.0, 2.0)
    options = options or {}

    ------------------------------------------------------
    -- ox_target
    ------------------------------------------------------

    if Bridge.Target.Type == "ox" then

        exports.ox_target:addBoxZone({

            name = id,

            coords = coords,

            size = size,

            rotation = options.rotation or 0.0,

            debug = Config.Debug,

            options = options.options or {}

        })

        return

    end

    ------------------------------------------------------
    -- qb-target
    ------------------------------------------------------

    if Bridge.Target.Type == "qb" then

        exports["qb-target"]:AddBoxZone(

            id,

            coords,

            size.x,

            size.y,

            {

                heading = options.rotation or 0,

                debugPoly = Config.Debug,

                minZ = coords.z - 1,

                maxZ = coords.z + 2

            },

            {

                options = options.options or {},

                distance = options.distance or 2.0

            }

        )

        return

    end

    ------------------------------------------------------
    -- interact
    ------------------------------------------------------

    if Bridge.Target.Type == "interact" then

        exports.interact:AddInteraction({

            coords = coords,

            distance = options.distance or 2.0,

            interactDst = options.distance or 2.0,

            id = id,

            options = options.options or {}

        })

        return

    end

end

----------------------------------------------------------
-- Remove Zone
----------------------------------------------------------

function Bridge.Target.Remove(id)

    if Bridge.Target.Type == "ox" then

        exports.ox_target:removeZone(id)

        return

    end

    if Bridge.Target.Type == "qb" then

        exports["qb-target"]:RemoveZone(id)

        return

    end

    if Bridge.Target.Type == "interact" then

        exports.interact:RemoveInteraction(id)

        return

    end

end

----------------------------------------------------------
-- Register Hotel Reception
----------------------------------------------------------

function Bridge.Target.RegisterReception(hotel)

    if not hotel.reception then
        return
    end

    Bridge.Target.AddBoxZone(

        "hotel_reception_" .. hotel.id,

        vec3(
            hotel.reception.coords.x,
            hotel.reception.coords.y,
            hotel.reception.coords.z
        ),

        vec3(1.5, 1.5, 2.0),

        {

            distance = 2.0,

            options = {

                {

                    label = "Open Reception",

                    icon = "fas fa-hotel",

                    onSelect = function()

                        TriggerEvent(
                            "hotel:openReception",
                            hotel.id
                        )

                    end

                }

            }

        }

    )

end

----------------------------------------------------------
-- Register Room Entrance
----------------------------------------------------------

function Bridge.Target.RegisterRoom(hotelId, room)

    if not room.entrance then
        return
    end

    local pos = room.entrance.coords or room.entrance

    Bridge.Target.AddBoxZone(

        ("hotel_room_%s_%s")
            :format(hotelId, room.id),

        vec3(pos.x, pos.y, pos.z),

        vec3(1.0, 1.0, 2.0),

        {

            distance = 1.5,

            options = {

                {

                    label = "Enter Room",

                    icon = "fas fa-door-open",

                    onSelect = function()

                        TriggerEvent(
                            "hotel:enterRoom",
                            hotelId,
                            room.id
                        )

                    end

                }

            }

        }

    )

end

----------------------------------------------------------
-- Register All Hotels
----------------------------------------------------------

CreateThread(function()

    Wait(2500)

    for _, hotel in pairs(Config.Hotels or {}) do

        Bridge.Target.RegisterReception(hotel)

        local rooms =
            hotel.rooms
            or Config.Rooms[hotel.id]
            or {}

        for _, room in pairs(rooms) do

            Bridge.Target.RegisterRoom(
                hotel.id,
                room
            )

        end

    end

end)

----------------------------------------------------------
-- Exports
----------------------------------------------------------

exports("TargetType", function()

    return Bridge.Target.Type

end)

exports("TargetAddBoxZone", Bridge.Target.AddBoxZone)

exports("TargetRemoveZone", Bridge.Target.Remove)

exports("TargetRegisterReception", Bridge.Target.RegisterReception)

exports("TargetRegisterRoom", Bridge.Target.RegisterRoom)
