--========================================================--
-- Standalone Hotel Framework
-- server/notifications.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Notifications = Hotel.Notifications or {}

----------------------------------------------------------
-- Send Notification
----------------------------------------------------------

function Hotel.Notify(src, message, notifyType)

    if not src then return end

    TriggerClientEvent(
        "hotel:notify",
        src,
        tostring(message),
        notifyType or "inform"
    )

end

function Hotel.NotifySuccess(src, message)

    TriggerClientEvent(
        "hotel:notifySuccess",
        src,
        tostring(message)
    )

end

function Hotel.NotifyError(src, message)

    TriggerClientEvent(
        "hotel:notifyError",
        src,
        tostring(message)
    )

end

function Hotel.NotifyWarning(src, message)

    TriggerClientEvent(
        "hotel:notifyWarning",
        src,
        tostring(message)
    )

end

function Hotel.NotifyAll(message)

    TriggerClientEvent(
        "hotel:notify",
        -1,
        tostring(message),
        "inform"
    )

end

function Hotel.Announcement(title, message)

    TriggerClientEvent(
        "hotel:announcement",
        -1,
        title,
        message
    )

end

----------------------------------------------------------
-- Events
----------------------------------------------------------

RegisterNetEvent("hotel:testNotify", function()

    local src = source

    Hotel.Notify(
        src,
        "Notification test."
    )

end)

RegisterNetEvent("hotel:testAnnouncement", function()

    Hotel.Announcement(
        "Hotel",
        "Welcome to the hotel!"
    )

end)

----------------------------------------------------------
-- Exports
----------------------------------------------------------

exports("Notify", Hotel.Notify)

exports("NotifySuccess", Hotel.NotifySuccess)

exports("NotifyError", Hotel.NotifyError)

exports("NotifyWarning", Hotel.NotifyWarning)

exports("NotifyAll", Hotel.NotifyAll)

exports("Announcement", Hotel.Announcement)
