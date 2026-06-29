local Notify = require "client.notifications"

local Boss = {
    open      = false,
    hotelId   = nil,
    dashboard = nil,
}

local function OpenBossMenu(hotelId)
    local dashboard = lib.callback.await("hotel:getDashboard", false, hotelId)
    if not dashboard then return Notify.Error("No permission.") end

    Boss.open      = true
    Boss.hotelId   = hotelId
    Boss.dashboard = dashboard

    SetNuiFocus(true, true)
    SendNUIMessage({ action = "openBoss", data = { hotel = hotelId, dashboard = dashboard } })
end

local function CloseBossMenu()
    Boss.open      = false
    Boss.hotelId   = nil
    Boss.dashboard = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeBoss" })
end

RegisterNetEvent("hotel:openBossMenu", function(hotelId)
    OpenBossMenu(hotelId)
end)

RegisterNUICallback("bossClose", function(_, cb)
    CloseBossMenu()
    cb({ ok = true })
end)

RegisterNUICallback("bossRefresh", function(_, cb)
    if not Boss.hotelId then cb({ ok = false }) return end
    local data = lib.callback.await("hotel:getDashboard", false, Boss.hotelId)
    if data then
        Boss.dashboard = data
        SendNUIMessage({ action = "updateDashboard", data = { hotel = Boss.hotelId, dashboard = data } })
    end
    cb({ ok = true })
end)

RegisterNUICallback("bossGetRooms", function(_, cb)
    if not Boss.hotelId then cb({ ok = false }) return end
    local rooms = lib.callback.await("hotel:getBossRooms", false, Boss.hotelId)
    if rooms then
        SendNUIMessage({ action = "bossRooms", data = { hotel = Boss.hotelId, rooms = rooms } })
    end
    cb({ ok = true })
end)

RegisterNUICallback("bossGetTenants", function(_, cb)
    if not Boss.hotelId then cb({ ok = false }) return end
    local tenants = lib.callback.await("hotel:getTenants", false, Boss.hotelId)
    if tenants then
        SendNUIMessage({ action = "bossTenants", data = { hotel = Boss.hotelId, tenants = tenants } })
    end
    cb({ ok = true })
end)

RegisterNUICallback("bossGetComplaints", function(_, cb)
    if not Boss.hotelId then cb({ ok = false }) return end
    local complaints = lib.callback.await("hotel:getComplaints", false, Boss.hotelId)
    if complaints then
        SendNUIMessage({ action = "bossComplaints", data = { hotel = Boss.hotelId, complaints = complaints } })
    end
    cb({ ok = true })
end)

RegisterNUICallback("bossChangePrice", function(data, cb)
    if not Boss.hotelId or not data then
        cb({ ok = false })
        return
    end

    TriggerServerEvent(
        "hotel:changePrice",
        Boss.hotelId,
        tonumber(data.roomId),
        tonumber(data.price)
    )

    cb({ ok = true })
end)

RegisterNUICallback("bossEvict", function(data, cb)
    if not data or not data.identifier then
        cb({ ok = false })
        return
    end

    TriggerServerEvent(
        "hotel:evictPlayer",
        Boss.hotelId,
        data.identifier
    )

    cb({ ok = true })
end)

RegisterNUICallback("bossFine", function(data, cb)
    if not data or not data.identifier then
        cb({ ok = false })
        return
    end

    TriggerServerEvent(
        "hotel:issueFine",
        Boss.hotelId,
        data.identifier,
        tonumber(data.amount) or 0,
        data.reason or "Hotel rule breach"
    )

    cb({ ok = true })
end)

RegisterNUICallback("bossResolveComplaint", function(data, cb)
    if not data or not data.id then
        cb({ ok = false })
        return
    end

    TriggerServerEvent(
        "hotel:resolveComplaint",
        Boss.hotelId,
        tonumber(data.id)
    )

    cb({ ok = true })
end)

RegisterNUICallback("bossRefund", function(data, cb)
    if not data or not data.identifier then
        cb({ ok = false })
        return
    end

    TriggerServerEvent(
        "hotel:refundPlayer",
        Boss.hotelId,
        data.identifier,
        tonumber(data.amount) or 0,
        data.reason or "Hotel refund"
    )

    cb({ ok = true })
end)

RegisterCommand("hotel_boss", function(_, args)
    local hotelId = args[1] or Boss.hotelId or "main_hotel"
    OpenBossMenu(hotelId)
end)

CreateThread(function()
    while true do
        if Boss.open then
            Wait(0)

            if IsControlJustPressed(0, 322) then
                CloseBossMenu()
            end
        else
            Wait(1000)
        end
    end
end)

exports("OpenHotelBossMenu", OpenBossMenu)
exports("CloseHotelBossMenu", CloseBossMenu)
