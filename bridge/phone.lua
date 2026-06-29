--========================================================--
-- Standalone Hotel Framework
-- bridge/phone.lua
--========================================================--

Bridge = Bridge or {}
Bridge.Phone = Bridge.Phone or {}

----------------------------------------------------------
-- Detect Installed Phone
----------------------------------------------------------

Bridge.Phone.Type = "standalone"

if GetResourceState("lb-phone") == "started" then
    Bridge.Phone.Type = "lb"

elseif GetResourceState("qb-phone") == "started" then
    Bridge.Phone.Type = "qb"

elseif GetResourceState("qs-smartphone") == "started" then
    Bridge.Phone.Type = "qs"

elseif GetResourceState("gksphone") == "started" then
    Bridge.Phone.Type = "gks"

elseif GetResourceState("gcphone") == "started" then
    Bridge.Phone.Type = "gc"

end

----------------------------------------------------------
-- Send Notification
----------------------------------------------------------

function Bridge.Phone.Notify(src, title, message)

    title = title or "Hotel"

    message = message or ""

    if Bridge.Phone.Type == "lb" then

        exports["lb-phone"]:SendNotification(src, {

            app = "Hotel",

            title = title,

            content = message

        })

        return true

    elseif Bridge.Phone.Type == "qb" then

        TriggerClientEvent(
            "qb-phone:client:CustomNotification",
            src,
            title,
            message,
            "fas fa-hotel"
        )

        return true

    elseif Bridge.Phone.Type == "qs" then

        TriggerClientEvent(
            "qs-smartphone:client:notify",
            src,
            title,
            message
        )

        return true

    elseif Bridge.Phone.Type == "gks" then

        TriggerClientEvent(
            "gksphone:notifi",
            src,
            {
                title = title,
                message = message
            }
        )

        return true

    elseif Bridge.Phone.Type == "gc" then

        TriggerClientEvent(
            "gcPhone:notify",
            src,
            title,
            message
        )

        return true

    end

    --------------------------------------------------
    -- Standalone Fallback
    --------------------------------------------------

    TriggerClientEvent(
        "chat:addMessage",
        src,
        {
            color = {52,152,219},
            multiline = true,
            args = {
                title,
                message
            }
        }
    )

    return true

end

----------------------------------------------------------
-- Hotel Reservation Confirmation
----------------------------------------------------------

function Bridge.Phone.Booking(src, hotelName, roomNumber)

    Bridge.Phone.Notify(

        src,

        "Hotel Booking",

        ("Reservation confirmed.\n%s\nRoom %s")
        :format(
            hotelName,
            roomNumber
        )

    )

end

----------------------------------------------------------
-- Rental Reminder
----------------------------------------------------------

function Bridge.Phone.Reminder(src, hotelName, hoursLeft)

    Bridge.Phone.Notify(

        src,

        "Hotel Reminder",

        ("%s expires in %s hour(s).")
        :format(
            hotelName,
            hoursLeft
        )

    )

end

----------------------------------------------------------
-- Eviction Notice
----------------------------------------------------------

function Bridge.Phone.Eviction(src)

    Bridge.Phone.Notify(

        src,

        "Hotel",

        "Your hotel rental has ended."

    )

end

----------------------------------------------------------
-- Exports
----------------------------------------------------------

exports("PhoneNotify", Bridge.Phone.Notify)

exports("PhoneBooking", Bridge.Phone.Booking)

exports("PhoneReminder", Bridge.Phone.Reminder)

exports("PhoneEviction", Bridge.Phone.Eviction)

exports("PhoneType", function()

    return Bridge.Phone.Type

end)
