local Notify = require "client.notifications"

local active  = false
local hotelId = nil
local roomId  = nil

RegisterCommand("hotel_clean", function(_, args)
    local hId = args[1]
    local rId = tonumber(args[2])
    if not hId or not rId then return Notify.Info("/hotel_clean [hotelId] [roomId]") end
    if active then return Notify.Error("You are already cleaning.") end

    local ok, reason = lib.callback.await("hotel:requestCleaning", false, hId, rId)
    if not ok then return Notify.Error(reason or "You cannot clean this room.") end

    active  = true
    hotelId = hId
    roomId  = rId

    Notify.Info("Cleaning room...")
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_MAID_CLEAN", 0, true)

    local success = true
    for _ = 1, 5 do
        Wait(1000)
        if IsPedDeadOrDying(PlayerPedId(), true) then success = false break end
    end

    ClearPedTasks(PlayerPedId())

    if success then
        TriggerServerEvent("hotel:finishCleaning", hotelId, roomId)
        Notify.Success("Room cleaned.")
    else
        Notify.Info("Cleaning cancelled.")
    end

    active  = false
    hotelId = nil
    roomId  = nil
end, false)

exports("IsCleaningHotelRoom", function() return active end)
