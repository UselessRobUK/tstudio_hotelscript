--========================================================--
-- Standalone Hotel Framework
-- client/phone.lua
--========================================================--

local Phone = {}

Phone.Type = "standalone"

if GetResourceState("qb-phone") == "started" then
    Phone.Type = "qb-phone"
elseif GetResourceState("qs-smartphone") == "started" then
    Phone.Type = "qs-smartphone"
elseif GetResourceState("gksphone") == "started" then
    Phone.Type = "gksphone"
elseif GetResourceState("lb-phone") == "started" then
    Phone.Type = "lb-phone"
end

local function Notify(msg)
    TriggerEvent("hotel:notify", msg)
end

function Phone.Send(title, message)
    title = title or "Hotel"
    message = message or ""

    if Phone.Type == "qb-phone" then
        TriggerServerEvent("hotel:phone:qbMessage", title, message)
        return
    end

    if Phone.Type == "qs-smartphone" then
        TriggerServerEvent("hotel:phone:qsMessage", title, message)
        return
    end

    if Phone.Type == "gksphone" then
        TriggerServerEvent("hotel:phone:gksMessage", title, message)
        return
    end

    if Phone.Type == "lb-phone" then
        TriggerServerEvent("hotel:phone:lbMessage", title, message)
        return
    end

    Notify(("[%s] %s"):format(title, message))
end

RegisterNetEvent("hotel:phoneMessage", function(title, message)
    Phone.Send(title, message)
end)

RegisterNetEvent("hotel:bookingReminder", function(roomId, expires)
    Phone.Send(
        "Hotel Booking",
        ("Your room %s booking expires at %s."):format(
            roomId,
            expires or "soon"
        )
    )
end)

RegisterNetEvent("hotel:invoiceNotice", function(amount, reason)
    Phone.Send(
        "Hotel Invoice",
        ("You received a hotel invoice for £%s. Reason: %s"):format(
            amount or 0,
            reason or "N/A"
        )
    )
end)

RegisterNetEvent("hotel:complaintNotice", function(status)
    Phone.Send(
        "Hotel Complaint",
        ("Your complaint status has changed to: %s"):format(status or "updated")
    )
end)

RegisterCommand("hotel_phone_test", function()
    Phone.Send("Hotel", "Phone notification test.")
end)

exports("SendHotelPhoneMessage", Phone.Send)

exports("GetHotelPhoneType", function()
    return Phone.Type
end)
