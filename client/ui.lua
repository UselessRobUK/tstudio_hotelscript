local Notify = require "client.notifications"

local NuiOpen      = false
local CurrentHotel = nil

local function OpenUI(action, payload)
    NuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = action, data = payload or {} })
end

local function CloseUI()
    NuiOpen      = false
    CurrentHotel = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
end

RegisterNetEvent("hotel:openMenu", function(hotelId)
    CurrentHotel  = hotelId
    local rooms   = lib.callback.await("hotel:getRooms", false, hotelId)
    OpenUI("openHotel", { hotel = hotelId, rooms = rooms or {} })
end)

RegisterNetEvent("hotel:openBossMenu", function(hotelId)
    CurrentHotel     = hotelId
    local dashboard  = lib.callback.await("hotel:getDashboard", false, hotelId)
    if not dashboard then return Notify.Error("No permission.") end
    OpenUI("openBoss", { hotel = hotelId, dashboard = dashboard })
end)

RegisterNetEvent("hotel:openComplaints", function(hotelId)
    CurrentHotel       = hotelId
    local complaints   = lib.callback.await("hotel:getComplaints", false, hotelId)
    if not complaints then return Notify.Error("No permission.") end
    OpenUI("openComplaints", { hotel = hotelId, complaints = complaints })
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

RegisterNetEvent("hotel:uiRefreshRooms", function()
    if not CurrentHotel or not NuiOpen then return end
    local rooms = lib.callback.await("hotel:getRooms", false, CurrentHotel)
    SendNUIMessage({ action = "updateRooms", data = { hotel = CurrentHotel, rooms = rooms or {} } })
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

exports("OpenHotelUI", function(hotelId)
    TriggerEvent("hotel:openMenu", hotelId)
end)

exports("CloseHotelUI", CloseUI)

exports("IsHotelUIOpen", function()
    return NuiOpen
end)
