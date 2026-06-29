--========================================================--
-- Standalone Hotel Framework
-- client/booking.lua
--========================================================--

local Booking = {
    open = false,
    hotelId = nil,
    rooms = {}
}

local function Notify(msg)
    TriggerEvent("hotel:notify", msg)
end

local function OpenBooking(hotelId)
    Booking.open = true
    Booking.hotelId = hotelId

    SetNuiFocus(true, true)

    TriggerServerEvent("hotel:getBookingRooms", hotelId)
end

local function CloseBooking()
    Booking.open = false
    Booking.hotelId = nil
    Booking.rooms = {}

    SetNuiFocus(false, false)

    SendNUIMessage({
        action = "closeBooking"
    })
end

RegisterNetEvent("hotel:openBooking", function(hotelId)
    OpenBooking(hotelId)
end)

RegisterNetEvent("hotel:receiveBookingRooms", function(hotelId, rooms)
    Booking.hotelId = hotelId
    Booking.rooms = rooms or {}

    SendNUIMessage({
        action = "openBooking",
        data = {
            hotel = hotelId,
            rooms = Booking.rooms
        }
    })
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

RegisterNetEvent("hotel:bookingCreated", function(roomId)
    Notify(("Booking confirmed for room %s."):format(roomId))

    if Booking.hotelId then
        TriggerServerEvent("hotel:getBookingRooms", Booking.hotelId)
    end
end)

RegisterNetEvent("hotel:bookingCancelled", function()
    Notify("Booking cancelled.")

    if Booking.hotelId then
        TriggerServerEvent("hotel:getBookingRooms", Booking.hotelId)
    end
end)

RegisterNetEvent("hotel:bookingExtended", function()
    Notify("Booking extended.")

    if Booking.hotelId then
        TriggerServerEvent("hotel:getBookingRooms", Booking.hotelId)
    end
end)

RegisterNetEvent("hotel:bookingFailed", function(reason)
    Notify(reason or "Booking failed.")
end)

RegisterCommand("hotel_book", function(_, args)
    local hotelId = args[1] or "main_hotel"
    OpenBooking(hotelId)
end)

CreateThread(function()
    while true do
        if Booking.open then
            Wait(0)

            if IsControlJustPressed(0, 322) then
                CloseBooking()
            end
        else
            Wait(1000)
        end
    end
end)

exports("OpenHotelBooking", OpenBooking)
exports("CloseHotelBooking", CloseBooking)
