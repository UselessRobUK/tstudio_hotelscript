--========================================================--
-- Standalone Hotel Framework
-- client/npc.lua
--========================================================--

local NPCs = {}
local UsingOxTarget = GetResourceState("ox_target") == "started"

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function LoadModel(model)
    local hash = type(model) == "number" and model or joaat(model)

    if not IsModelInCdimage(hash) then
        print(("[Hotel] Invalid NPC model: %s"):format(model))
        return nil
    end

    RequestModel(hash)

    while not HasModelLoaded(hash) do
        Wait(10)
    end

    return hash
end

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

--------------------------------------------------
-- Spawn NPC
--------------------------------------------------

local function SpawnReception(hotel)

    if NPCs[hotel.id] then
        return
    end

    local hash = LoadModel(hotel.npc.model)

    if not hash then
        return
    end

    local c = hotel.npc.coords

    local ped = CreatePed(
        4,
        hash,
        c.x,
        c.y,
        c.z - 1.0,
        c.w,
        false,
        true
    )

    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    SetPedCanRagdoll(ped, false)
    SetPedDiesWhenInjured(ped, false)

    TaskStartScenarioInPlace(
        ped,
        "WORLD_HUMAN_CLIPBOARD",
        0,
        true
    )

    SetModelAsNoLongerNeeded(hash)

    NPCs[hotel.id] = ped

    --------------------------------------------------
    -- ox_target Support
    --------------------------------------------------

    if UsingOxTarget then

        exports.ox_target:addLocalEntity(ped, {

            {
                name = "hotel_" .. hotel.id,

                icon = "fa-solid fa-hotel",

                label = "Speak to Reception",

                distance = 2.0,

                onSelect = function()

                    TriggerEvent("hotel:openMenu", hotel.id)

                end
            }

        })

    end

end

--------------------------------------------------
-- Startup
--------------------------------------------------

CreateThread(function()

    Wait(1000)

    for _, hotel in pairs(Config.Hotels) do
        SpawnReception(hotel)
    end

end)

--------------------------------------------------
-- Fallback Interaction
--------------------------------------------------

if not UsingOxTarget then

CreateThread(function()

    while true do

        local sleep = 1000

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for hotelId, npc in pairs(NPCs) do

            if DoesEntityExist(npc) then

                local npcCoords = GetEntityCoords(npc)

                local dist = #(coords - npcCoords)

                if dist < 8.0 then

                    sleep = 0

                    DrawText3D(
                        vector3(
                            npcCoords.x,
                            npcCoords.y,
                            npcCoords.z + 1.05
                        ),
                        "[E] Speak to Reception"
                    )

                    if dist < 2.0 then

                        if IsControlJustReleased(0, 38) then

                            TriggerEvent(
                                "hotel:openMenu",
                                hotelId
                            )

                        end

                    end

                end

            end

        end

        Wait(sleep)

    end

end)

end

--------------------------------------------------
-- Simple Greeting Animation
--------------------------------------------------

RegisterNetEvent("hotel:npcGreeting", function(hotelId)

    local ped = NPCs[hotelId]

    if not ped then return end

    RequestAnimDict("gestures@m@standing@casual")

    while not HasAnimDictLoaded("gestures@m@standing@casual") do
        Wait(10)
    end

    TaskPlayAnim(
        ped,
        "gestures@m@standing@casual",
        "gesture_hello",
        8.0,
        -8.0,
        2500,
        48,
        0,
        false,
        false,
        false
    )

end)

--------------------------------------------------
-- Key Handover Animation
--------------------------------------------------

RegisterNetEvent("hotel:npcGiveKey", function(hotelId)

    local ped = NPCs[hotelId]

    if not ped then return end

    RequestAnimDict("mp_common")

    while not HasAnimDictLoaded("mp_common") do
        Wait(10)
    end

    TaskPlayAnim(
        ped,
        "mp_common",
        "givetake1_a",
        8.0,
        -8.0,
        2200,
        48,
        0,
        false,
        false,
        false
    )

end)

--------------------------------------------------
-- Cleanup
--------------------------------------------------

AddEventHandler("onResourceStop", function(resource)

    if resource ~= GetCurrentResourceName() then
        return
    end

    for _, ped in pairs(NPCs) do

        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end

    end

end)
