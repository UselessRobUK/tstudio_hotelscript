local Notify = require "client.notifications"

local Booking = {
    open    = false,
    hotelId = nil,
    rooms   = {},
}

local function OpenBooking(hotelId)
    local rooms     = lib.callback.await("hotel:getBookingRooms", false, hotelId)
    Booking.open    = true
    Booking.hotelId = hotelId
    Booking.rooms   = rooms or {}
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "openBooking", data = { hotel = hotelId, rooms = Booking.rooms } })
end

local function CloseBooking()
    Booking.open    = false
    Booking.hotelId = nil
    Booking.rooms   = {}
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeBooking" })
end

RegisterNetEvent("hotel:openBooking", function(hotelId)
    OpenBooking(hotelId)
end)

RegisterNUICallback("bookingClose", function(_, cb)
    CloseBooking()
    cb({ ok = true })
end)

RegisterNUICallback("bookRoom", function(data, cb)
    if not Booking.hotelId then
        cb({ ok = false, error = "No hotel selected" })
        return
    end

    if not data or not data.roomId then
        cb({ ok = false, error = "Invalid room" })
        return
    end

    TriggerServerEvent("hotel:createBooking", {
        hotelId = Booking.hotelId,
        roomId = tonumber(data.roomId),
        startTime = tonumber(data.startTime),
        endTime = tonumber(data.endTime),
        payment = data.payment or "bank"
    })

    cb({ ok = true })
end)

RegisterNUICallback("cancelBooking", function(data, cb)
    if not data or not data.bookingId then
        cb({ ok = false })
        return
    end

    TriggerServerEvent("hotel:cancelBooking", tonumber(data.bookingId))
    cb({ ok = true })
end)

RegisterNUICallback("extendBooking", function(data, cb)
    if not data or not data.bookingId or not data.hours then
        cb({ ok = false })
        return
    end

    TriggerServerEvent(
        "hotel:extendBooking",
        tonumber(data.bookingId),
        tonumber(data.hours),
        data.payment or "bank"
    )

    cb({ ok = true })
end)

local function RefreshRooms()
    if not Booking.hotelId then return end
    local rooms   = lib.callback.await("hotel:getBookingRooms", false, Booking.hotelId)
    Booking.rooms = rooms or {}
    SendNUIMessage({ action = "updateBookingRooms", data = { hotel = Booking.hotelId, rooms = Booking.rooms } })
end

RegisterNetEvent("hotel:bookingCreated", function(roomId)
    Notify.Success(("Booking confirmed for room %s."):format(roomId))
    RefreshRooms()
end)

RegisterNetEvent("hotel:bookingCancelled", function()
    Notify.Info("Booking cancelled.")
    RefreshRooms()
end)

RegisterNetEvent("hotel:bookingExtended", function()
    Notify.Info("Booking extended.")
    RefreshRooms()
end)

RegisterNetEvent("hotel:bookingFailed", function(reason)
    Notify.Error(reason or "Booking failed.")
end)

RegisterCommand("hotel_book", function(_, args)
    local hotelId = args[1] or "main_hotel"
    OpenBooking(hotelId)
end)

exports("OpenHotelBooking", OpenBooking)
exports("CloseHotelBooking", CloseBooking)
