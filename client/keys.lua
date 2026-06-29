--========================================================--
-- Standalone Hotel Framework
-- client/keys.lua
--========================================================--

local Keys = {}

local UsingOxInventory = GetResourceState("ox_inventory") == "started"

--------------------------------------------------------
-- Notifications
--------------------------------------------------------

local function Notify(msg)
    TriggerEvent("hotel:notify", msg)
end

--------------------------------------------------------
-- Key Lookup
--------------------------------------------------------

local function KeyIndex(hotelId, roomId)

    for i = 1, #Keys do

        local key = Keys[i]

        if key.hotel == hotelId and key.room == roomId then
            return i
        end

    end

    return nil

end

--------------------------------------------------------
-- Add Key
--------------------------------------------------------

RegisterNetEvent("hotel:receiveKey", function(data)

    if not data then return end

    local index = KeyIndex(data.hotel, data.room)

    if index then
        Keys[index] = data
    else
        Keys[#Keys + 1] = data
    end

    Notify(("Received key for Room %s"):format(data.room))

end)

--------------------------------------------------------
-- Remove Key
--------------------------------------------------------

RegisterNetEvent("hotel:removeKey", function(hotelId, roomId)

    local index = KeyIndex(hotelId, roomId)

    if not index then return end

    table.remove(Keys, index)

    Notify("Hotel key removed.")

end)

--------------------------------------------------------
-- Has Key
--------------------------------------------------------

function HasHotelKey(hotelId, roomId)

    local now = os.time()

    for _, key in pairs(Keys) do

        if key.hotel == hotelId
        and key.room == roomId then

            if key.expires then

                if key.expires > now then
                    return true
                end

            else
                return true
            end

        end

    end

    return false

end

exports("HasHotelKey", HasHotelKey)

--------------------------------------------------------
-- Get Keys
--------------------------------------------------------

exports("GetHotelKeys", function()
    return Keys
end)

--------------------------------------------------------
-- Key Expiry Check
--------------------------------------------------------

CreateThread(function()

    while true do

        Wait(60000)

        local now = os.time()

        for i = #Keys, 1, -1 do

            local key = Keys[i]

            if key.expires then

                if key.expires <= now then

                    table.remove(Keys, i)

                    Notify(("Room %s key expired"):format(key.room))

                end

            end

        end

    end

end)

--------------------------------------------------------
-- Use Key (Standalone)
--------------------------------------------------------

RegisterCommand("hotelkey", function(_, args)

    local room = tonumber(args[1])

    if not room then

        Notify("/hotelkey [roomId]")

        return

    end

    for _, key in pairs(Keys) do

        if key.room == room then

            TriggerServerEvent(
                "hotel:requestRoomEntry",
                key.hotel,
                key.room
            )

            return

        end

    end

    Notify("You don't own that room key.")

end)

--------------------------------------------------------
-- ox_inventory Sync
--------------------------------------------------------

if UsingOxInventory then

CreateThread(function()

    Wait(3000)

    while true do

        Wait(30000)

        local items = exports.ox_inventory:Search(
            "slots",
            "hotel_key"
        )

        Keys = {}

        for _, item in pairs(items) do

            if item.metadata then

                Keys[#Keys + 1] = {

                    hotel = item.metadata.hotel,

                    room = item.metadata.room,

                    expires = item.metadata.expires

                }

            end

        end

    end

end)

end

--------------------------------------------------------
-- Resource Start
--------------------------------------------------------

AddEventHandler("onClientResourceStart", function(resource)

    if resource ~= GetCurrentResourceName() then
        return
    end

    TriggerServerEvent("hotel:syncKeys")

end)

--------------------------------------------------------
-- Server Sync
--------------------------------------------------------

RegisterNetEvent("hotel:syncKeys", function(serverKeys)

    Keys = serverKeys or {}

end)

--------------------------------------------------------
-- Debug Command
--------------------------------------------------------

RegisterCommand("hotelkeys", function()

    print("========== HOTEL KEYS ==========")

    for _, key in pairs(Keys) do

        print(json.encode(key))

    end

    print("===============================")

end)

--------------------------------------------------------
-- Cleanup
--------------------------------------------------------

AddEventHandler("onResourceStop", function(resource)

    if resource ~= GetCurrentResourceName() then
        return
    end

    Keys = {}

end)
