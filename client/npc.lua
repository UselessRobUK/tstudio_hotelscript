local Config = require "configs.shared.main"
local Hotels = require "configs.shared.hotels"
local Utils  = require "client.utils"

local NPCs          = {}
local UsingOxTarget = GetResourceState("ox_target") == "started"

local function SpawnReception(hotel)
    if NPCs[hotel.id] then return end
    if not hotel.reception then return end

    local hash = Utils.LoadModel(hotel.reception.model)
    if not hash then return end

    local c   = hotel.reception.coords
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
    local npcKey
    local npcAction

    npcKey = lib.addKeybind({
        name        = 'hotel_npc_interact',
        description = 'Speak to Reception',
        defaultKey  = 'e',
        disabled    = true,
        onPressed   = function()
            if npcAction then npcAction() end
        end,
    })

    for _, hotel in pairs(Hotels) do
        if hotel.reception then
            local c = hotel.reception.coords
            lib.zones.sphere({
                coords  = vec3(c.x, c.y, c.z),
                radius  = 2.0,
                debug   = Config.Debug,
                onEnter = function()
                    npcAction = function() TriggerEvent("hotel:openMenu", hotel.id) end
                    lib.showTextUI("[E] Speak to Reception", { position = 'right-center' })
                    npcKey:enable()
                end,
                onExit  = function()
                    npcAction = nil
                    lib.hideTextUI()
                    npcKey:disable()
                end,
            })
        end
    end
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
