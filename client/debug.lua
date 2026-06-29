--========================================================--
-- Standalone Hotel Framework
-- client/debug.lua
--========================================================--

Debug = {}

Debug.Enabled = Config.Debug or false

----------------------------------------------------------
-- Internal State
----------------------------------------------------------

local drawMarkers = false
local drawRoomIds = false
local drawNPCs = false

----------------------------------------------------------
-- Logging
----------------------------------------------------------

function Debug.Print(...)
    if not Debug.Enabled then return end

    print("^3[HOTEL DEBUG]^7", ...)
end

function Debug.Error(...)
    print("^1[HOTEL ERROR]^7", ...)
end

function Debug.Success(...)
    if not Debug.Enabled then return end

    print("^2[HOTEL]^7", ...)
end

----------------------------------------------------------
-- Draw 3D Text
----------------------------------------------------------

local function Draw3D(coords, text)

    SetDrawOrigin(coords.x, coords.y, coords.z, 0)

    SetTextScale(0.30, 0.30)

    SetTextFont(4)

    SetTextCentre(true)

    SetTextEntry("STRING")

    AddTextComponentString(text)

    DrawText(0.0, 0.0)

    ClearDrawOrigin()

end

----------------------------------------------------------
-- Draw Hotel Markers
----------------------------------------------------------

CreateThread(function()

    while true do

        if not drawMarkers then

            Wait(1000)

        else

            Wait(0)

            for _, hotel in pairs(Config.Hotels or {}) do

                if hotel.entrance then

                    DrawMarker(
                        1,
                        hotel.entrance.x,
                        hotel.entrance.y,
                        hotel.entrance.z - 1.0,
                        0.0,0.0,0.0,
                        0.0,0.0,0.0,
                        1.0,1.0,1.0,
                        0,255,0,120,
                        false,true,2
                    )

                end

                if hotel.rooms then

                    for _, room in pairs(hotel.rooms) do

                        if room.entrance then

                            local pos = room.entrance.coords or room.entrance

                            DrawMarker(
                                2,
                                pos.x,
                                pos.y,
                                pos.z,
                                0.0,0.0,0.0,
                                0.0,0.0,0.0,
                                0.35,0.35,0.35,
                                255,255,0,150,
                                false,true,2
                            )

                            if drawRoomIds then

                                Draw3D(
                                    vector3(
                                        pos.x,
                                        pos.y,
                                        pos.z + 0.5
                                    ),
                                    tostring(room.id)
                                )

                            end

                        end

                    end

                end

            end

        end

    end

end)

----------------------------------------------------------
-- Draw NPC Labels
----------------------------------------------------------

CreateThread(function()

    while true do

        if not drawNPCs then

            Wait(1000)

        else

            Wait(0)

            for _, hotel in pairs(Config.Hotels or {}) do

                if hotel.npc then

                    Draw3D(
                        vector3(
                            hotel.npc.coords.x,
                            hotel.npc.coords.y,
                            hotel.npc.coords.z + 1.2
                        ),
                        hotel.name
                    )

                end

            end

        end

    end

end)

----------------------------------------------------------
-- Commands
----------------------------------------------------------

RegisterCommand("hotel_debug", function()

    Debug.Enabled = not Debug.Enabled

    print("Hotel Debug:", Debug.Enabled)

end)

RegisterCommand("hotel_markers", function()

    drawMarkers = not drawMarkers

    print("Hotel Markers:", drawMarkers)

end)

RegisterCommand("hotel_rooms", function()

    drawRoomIds = not drawRoomIds

    print("Room Labels:", drawRoomIds)

end)

RegisterCommand("hotel_npcs", function()

    drawNPCs = not drawNPCs

    print("NPC Labels:", drawNPCs)

end)

RegisterCommand("hotel_dump", function()

    print(json.encode(Config.Hotels, {
        indent = true
    }))

end)

----------------------------------------------------------
-- Resource State
----------------------------------------------------------

AddEventHandler("onClientResourceStart", function(resource)

    if resource ~= GetCurrentResourceName() then
        return
    end

    Debug.Success("Debug Module Loaded")

end)

----------------------------------------------------------
-- Exports
----------------------------------------------------------

exports("DebugPrint", Debug.Print)

exports("DebugError", Debug.Error)

exports("DebugSuccess", Debug.Success)

exports("IsDebugEnabled", function()

    return Debug.Enabled

end)
