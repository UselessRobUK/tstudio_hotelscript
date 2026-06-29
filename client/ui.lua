--========================================================--
-- Standalone Hotel Framework
-- client/ui.lua
--========================================================--

local NuiOpen = false
local CurrentHotel = nil

local function Notify(msg)
    TriggerEvent("hotel:notify", msg)
end

local function OpenUI(action, payload)
    NuiOpen = true
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = action,
        data = payload or {}
    })
end

local function CloseUI()
    NuiOpen = false
    CurrentHotel = nil
    SetNuiFocus(false, false)

    SendNUIMessage({
        action = "close"
    })
end

RegisterNetEvent("hotel:openMenu", function(hotelId)
    CurrentHotel = hotelId

    TriggerServerEvent("hotel:getRooms", hotelId)
end)

RegisterNetEvent("hotel:receiveRooms", function(hotelId, rooms)
    CurrentHotel = hotelId

    OpenUI("openHotel", {
        hotel = hotelId,
        rooms = rooms or {}
    })
end)

RegisterNetEvent("hotel:openBossMenu", function(hotelId)
    CurrentHotel = hotelId

    TriggerServerEvent("hotel:getDashboard", hotelId)
end)

RegisterNetEvent("hotel:receiveDashboard", function(hotelId, data)
    CurrentHotel = hotelId

    OpenUI("openBoss", {
        hotel = hotelId,
        dashboard = data or {}
    })
end)

RegisterNetEvent("hotel:openComplaints", function(hotelId)
    CurrentHotel = hotelId

    TriggerServerEvent("hotel:getComplaints", hotelId)
end)

RegisterNetEvent("hotel:receiveComplaints", function(hotelId, complaints)
    OpenUI("openComplaints", {
        hotel = hotelId,
        complaints = complaints or {}
    })
end)

RegisterNUICallback("close", function(_, cb)
    CloseUI()
    cb({ ok = true })
end)

RegisterNUICallback("rentRoom", function(data, cb)
    if not CurrentHotel then
        cb({ ok = false, error = "No hotel selected" })
        return
    end

    if not data or not data.roomId then
        cb({ ok = false, error = "Invalid room" })
        return
    end

    TriggerServerEvent("hotel:rentRoom", {
        hotelId = CurrentHotel,
        roomId = tonumber(data.roomId),
        payment = data.payment or "cash"
    })

    cb({ ok = true })
end)

RegisterNUICallback("enterRoom", function(data, cb)
    if not CurrentHotel or not data.roomId then
        cb({ ok = false })
        return
    end

    TriggerEvent("hotel:enterRoom", CurrentHotel, tonumber(data.roomId))

    cb({ ok = true })
end)

RegisterNUICallback("submitComplaint", function(data, cb)
    if not CurrentHotel then
        cb({ ok = false })
        return
    end

    local message = data and data.message

    if not message or message == "" then
        cb({ ok = false, error = "Empty complaint" })
        return
    end

    TriggerServerEvent("hotel:submitComplaint", {
        hotel = CurrentHotel,
        message = message
    })

    cb({ ok = true })
end)

RegisterNUICallback("bossChangePrice", function(data, cb)
    TriggerServerEvent(
        "hotel:changePrice",
        CurrentHotel,
        tonumber(data.roomId),
        tonumber(data.price)
    )

    cb({ ok = true })
end)

RegisterNUICallback("bossEvict", function(data, cb)
    TriggerServerEvent("hotel:evictPlayer", data.identifier)
    cb({ ok = true })
end)

RegisterNUICallback("bossFine", function(data, cb)
    TriggerServerEvent(
        "hotel:issueFine",
        data.identifier,
        tonumber(data.amount),
        data.reason or "Hotel fine"
    )

    cb({ ok = true })
end)

RegisterNUICallback("resolveComplaint", function(data, cb)
    TriggerServerEvent("hotel:resolveComplaint", tonumber(data.id))
    cb({ ok = true })
end)

RegisterNetEvent("hotel:notify", function(msg)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(tostring(msg))
    EndTextCommandThefeedPostTicker(false, false)
end)

RegisterNetEvent("hotel:uiRefreshRooms", function()
    if CurrentHotel then
        TriggerServerEvent("hotel:getRooms", CurrentHotel)
    end
end)

RegisterCommand("hotel_closeui", function()
    if NuiOpen then
        CloseUI()
    end
end)

RegisterCommand("hotel_boss", function(_, args)
    local hotelId = args[1] or CurrentHotel or "main_hotel"
    TriggerEvent("hotel:openBossMenu", hotelId)
end)

CreateThread(function()
    while true do
        if NuiOpen then
            Wait(0)

            if IsControlJustPressed(0, 322) then -- ESC
                CloseUI()
            end
        else
            Wait(1000)
        end
    end
end)

exports("OpenHotelUI", function(hotelId)
    TriggerEvent("hotel:openMenu", hotelId)
end)

exports("CloseHotelUI", CloseUI)

exports("IsHotelUIOpen", function()
    return NuiOpen
end)
