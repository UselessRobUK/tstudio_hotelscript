--========================================================--
-- Standalone Hotel Framework
-- client/stash.lua
--========================================================--

local Stash = {}

Stash.Type = "standalone"

if GetResourceState("ox_inventory") == "started" then
    Stash.Type = "ox"
elseif GetResourceState("qb-inventory") == "started" then
    Stash.Type = "qb"
elseif GetResourceState("qs-inventory") == "started" then
    Stash.Type = "qs"
end

local function Notify(msg)
    TriggerEvent("hotel:notify", msg)
end

function Stash.Open(hotelId, roomId)
    local stashId = ("hotel_%s_%s"):format(hotelId, roomId)

    if Stash.Type == "ox" then
        exports.ox_inventory:openInventory("stash", stashId)
        return
    end

    if Stash.Type == "qb" then
        TriggerServerEvent("inventory:server:OpenInventory", "stash", stashId, {
            maxweight = 50000,
            slots = 30
        })

        TriggerEvent("inventory:client:SetCurrentStash", stashId)
        return
    end

    if Stash.Type == "qs" then
        TriggerServerEvent("inventory:server:OpenInventory", "stash", stashId, {
            maxweight = 50000,
            slots = 30
        })

        return
    end

    Notify("Standalone stash opened: " .. stashId)
end

RegisterNetEvent("hotel:openStashClient", function(hotelId, roomId)
    Stash.Open(hotelId, roomId)
end)

RegisterNetEvent("hotel:openStash", function(hotelId, roomId)
    TriggerServerEvent("hotel:requestStashAccess", hotelId, roomId)
end)

RegisterNetEvent("hotel:stashApproved", function(hotelId, roomId)
    Stash.Open(hotelId, roomId)
end)

RegisterCommand("hotelstash", function(_, args)
    local hotelId = args[1]
    local roomId = tonumber(args[2])

    if not hotelId or not roomId then
        Notify("/hotelstash [hotelId] [roomId]")
        return
    end

    TriggerServerEvent("hotel:requestStashAccess", hotelId, roomId)
end)

exports("OpenHotelStash", function(hotelId, roomId)
    TriggerServerEvent("hotel:requestStashAccess", hotelId, roomId)
end)
