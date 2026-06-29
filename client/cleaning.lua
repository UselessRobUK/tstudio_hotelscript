--========================================================--
-- Standalone Hotel Framework
-- client/cleaning.lua
--========================================================--

local Cleaning = {
    active = false,
    hotelId = nil,
    roomId = nil
}

local function Notify(msg)
    TriggerEvent("hotel:notify", msg)
end

local function PlayCleaningAnim()
    TaskStartScenarioInPlace(
        PlayerPedId(),
        "WORLD_HUMAN_MAID_CLEAN",
        0,
        true
    )
end

local function StopCleaningAnim()
    ClearPedTasks(PlayerPedId())
end

RegisterNetEvent("hotel:startCleaning", function(hotelId, roomId)
    if Cleaning.active then
        Notify("You are already cleaning.")
        return
    end

    Cleaning.active = true
    Cleaning.hotelId = hotelId
    Cleaning.roomId = roomId

    Notify("Cleaning room...")

    PlayCleaningAnim()

    local success = true

    for _ = 1, 5 do
        Wait(1000)

        if IsPedDeadOrDying(PlayerPedId(), true) then
            success = false
            break
        end
    end

    StopCleaningAnim()

    if success then
        TriggerServerEvent("hotel:finishCleaning", hotelId, roomId)
        Notify("Room cleaned.")
    else
        Notify("Cleaning cancelled.")
    end

    Cleaning.active = false
    Cleaning.hotelId = nil
    Cleaning.roomId = nil
end)

RegisterNetEvent("hotel:cleaningFailed", function(reason)
    Notify(reason or "You cannot clean this room.")
end)

RegisterCommand("hotel_clean", function(_, args)
    local hotelId = args[1] or "main_hotel"
    local roomId = tonumber(args[2])

    if not roomId then
        Notify("/hotel_clean [hotelId] [roomId]")
        return
    end

    TriggerServerEvent("hotel:requestCleaning", hotelId, roomId)
end)

exports("IsCleaningHotelRoom", function()
    return Cleaning.active
end)
