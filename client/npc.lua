local Config = require "configs.shared.main"
local Hotels = require "configs.shared.hotels"
local Utils  = require "client.utils"

local NPCs          = {}
local UsingOxTarget = GetResourceState("ox_target") == "started"

local function SpawnReception(hotel)
    if NPCs[hotel.id] then return end
    if not hotel.npc then return end

    local hash = Utils.LoadModel(hotel.npc.model)
    if not hash then return end

    local c   = hotel.npc.coords
    local ped = CreatePed(4, hash, c.x, c.y, c.z - 1.0, c.w, false, true)

    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedDiesWhenInjured(ped, false)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", 0, true)
    SetModelAsNoLongerNeeded(hash)

    NPCs[hotel.id] = ped

    if UsingOxTarget then
        exports.ox_target:addLocalEntity(ped, {
            {
                name     = "hotel_" .. hotel.id,
                icon     = "fa-solid fa-hotel",
                label    = "Speak to Reception",
                distance = 2.0,
                onSelect = function() TriggerEvent("hotel:openMenu", hotel.id) end,
            },
        })
    end
end

CreateThread(function()
    Wait(1000)
    for _, hotel in pairs(Hotels) do SpawnReception(hotel) end
end)

if not UsingOxTarget then
    CreateThread(function()
        while true do
            local sleep   = 1000
            local ped     = PlayerPedId()
            local coords  = GetEntityCoords(ped)

            for hotelId, npc in pairs(NPCs) do
                if DoesEntityExist(npc) then
                    local npcCoords = GetEntityCoords(npc)
                    local dist      = #(coords - npcCoords)
                    if dist < 8.0 then
                        sleep = 0
                        Utils.DrawText3D(vector3(npcCoords.x, npcCoords.y, npcCoords.z + 1.05), "[E] Speak to Reception")
                        if dist < 2.0 and IsControlJustReleased(0, Config.InteractKey) then
                            TriggerEvent("hotel:openMenu", hotelId)
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

RegisterNetEvent("hotel:npcGreeting", function(hotelId)
    local ped = NPCs[hotelId]
    if not ped then return end
    if not Utils.LoadAnimDict("gestures@m@standing@casual") then return end
    TaskPlayAnim(ped, "gestures@m@standing@casual", "gesture_hello", 8.0, -8.0, 2500, 48, 0, false, false, false)
end)

RegisterNetEvent("hotel:npcGiveKey", function(hotelId)
    local ped = NPCs[hotelId]
    if not ped then return end
    if not Utils.LoadAnimDict("mp_common") then return end
    TaskPlayAnim(ped, "mp_common", "givetake1_a", 8.0, -8.0, 2200, 48, 0, false, false, false)
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, ped in pairs(NPCs) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)
