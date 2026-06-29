--========================================================--
-- Standalone Hotel Framework
-- client/boss.lua
--========================================================--

local Boss = {
    open = false,
    hotelId = nil,
    dashboard = nil
}

local function Notify(msg)
    TriggerEvent("hotel:notify", msg)
end

local function OpenBossMenu(hotelId)
    Boss.open = true
    Boss.hotelId = hotelId

    SetNuiFocus(true, true)

    TriggerServerEvent("hotel:getDashboard", hotelId)
end

local function CloseBossMenu()
    Boss.open = false
    Boss.hotelId = nil
    Boss.dashboard = nil

    SetNuiFocus(false, false)

    SendNUIMessage({
        action = "closeBoss"
    })
end

RegisterNetEvent("hotel:openBossMenu", function(hotelId)
    OpenBossMenu(hotelId)
end)

RegisterNetEvent("hotel:receiveDashboard", function(hotelId, data)
    Boss.hotelId = hotelId
    Boss.dashboard = data or {}

    SendNUIMessage({
        action = "openBoss",
        data = {
            hotel = hotelId,
            dashboard = Boss.dashboard
        }
    })
end)

RegisterNetEvent("hotel:receiveBossRooms", function(hotelId, rooms)
    SendNUIMessage({
        action = "bossRooms",
        data = {
            hotel = hotelId,
            rooms = rooms or {}
        }
    })
end)

RegisterNetEvent("hotel:receiveTenants", function(hotelId, tenants)
    SendNUIMessage({
        action = "bossTenants",
        data = {
            hotel = hotelId,
            tenants = tenants or {}
        }
    })
end)

RegisterNetEvent("hotel:receiveComplaints", function(hotelId, complaints)
    SendNUIMessage({
        action = "bossComplaints",
        data = {
            hotel = hotelId,
            complaints = complaints or {}
        }
    })
end)

RegisterNUICallback("bossClose", function(_, cb)
    CloseBossMenu()
    cb({ ok = true })
end)

RegisterNUICallback("bossRefresh", function(_, cb)
    if Boss.hotelId then
        TriggerServerEvent("hotel:getDashboard", Boss.hotelId)
    end

    cb({ ok = true })
end)

RegisterNUICallback("bossGetRooms", function(_, cb)
    if Boss.hotelId then
        TriggerServerEvent("hotel:getBossRooms", Boss.hotelId)
    end

    cb({ ok = true })
end)

RegisterNUICallback("bossGetTenants", function(_, cb)
    if Boss.hotelId then
        TriggerServerEvent("hotel:getTenants", Boss.hotelId)
    end

    cb({ ok = true })
end)

RegisterNUICallback("bossGetComplaints", function(_, cb)
    if Boss.hotelId then
        TriggerServerEvent("hotel:getComplaints", Boss.hotelId)
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
