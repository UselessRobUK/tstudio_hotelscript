local Notify    = require "client.notifications"
local Config    = require "configs.shared.main"

local stashType = "standalone"

if GetResourceState("ox_inventory") == "started" then
    stashType = "ox"
elseif GetResourceState("qb-inventory") == "started" then
    stashType = "qb"
elseif GetResourceState("qs-inventory") == "started" then
    stashType = "qs"
end

local function OpenStash(hotelId, roomId)
    local stashId = ("hotel_%s_%s"):format(hotelId, roomId)

    if stashType == "ox" then
        exports.ox_inventory:openInventory("stash", stashId)
        return
    end

    if stashType == "qb" or stashType == "qs" then
        TriggerServerEvent("inventory:server:OpenInventory", "stash", stashId, {
            maxweight = Config.StashWeight or 50000,
            slots     = Config.StashSlots  or 30,
        })
        if stashType == "qb" then
            TriggerEvent("inventory:client:SetCurrentStash", stashId)
        end
        return
    end

    Notify.Info("Stash: " .. stashId)
end

-- server-push: admin/external opens a stash for this client directly
RegisterNetEvent("hotel:stashApproved", function(hotelId, roomId)
    OpenStash(hotelId, roomId)
end)

RegisterNetEvent("hotel:openStash", function(hotelId, roomId)
    local granted = lib.callback.await("hotel:requestStashAccess", false, hotelId, roomId)
    if not granted then return Notify.Error("You don't have access to this stash.") end
    OpenStash(hotelId, roomId)
end)

RegisterCommand("hotelstash", function(_, args)
    local hId = args[1]
    local rId = tonumber(args[2])
    if not hId or not rId then return Notify.Info("/hotelstash [hotelId] [roomId]") end
    local granted = lib.callback.await("hotel:requestStashAccess", false, hId, rId)
    if not granted then return Notify.Error("You don't have access to this stash.") end
    OpenStash(hId, rId)
end, false)

exports("OpenHotelStash", OpenStash)
