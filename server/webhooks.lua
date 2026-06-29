--========================================================--
-- Standalone Hotel Framework
-- server/webhooks.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Webhooks = Hotel.Webhooks or {}

----------------------------------------------------------
-- Configuration
----------------------------------------------------------

local DefaultColor = 3447003

local Colors = {
    success = 5763719,
    error = 15548997,
    warning = 16776960,
    info = 3447003
}

----------------------------------------------------------
-- Get Webhook URL
----------------------------------------------------------

local function GetWebhook(name)
    if not Config.Webhooks then
        return nil
    end

    return Config.Webhooks[name] or Config.Webhooks.default
end

----------------------------------------------------------
-- Send Webhook
----------------------------------------------------------

function Hotel.Webhooks.Send(webhookName, title, description, color)

    local url = GetWebhook(webhookName)

    if not url or url == "" then
        return
    end

    PerformHttpRequest(url, function() end, "POST", json.encode({

        username = "Hotel Framework",

        embeds = {

            {

                title = title,

                description = description,

                color = color or DefaultColor,

                footer = {

                    text = os.date("%d/%m/%Y %H:%M:%S")

                },

                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

            }

        }

    }), {

        ["Content-Type"] = "application/json"

    })

end

----------------------------------------------------------
-- Convenience Functions
----------------------------------------------------------

function Hotel.Webhooks.Rental(player, hotel, room)

    Hotel.Webhooks.Send(

        "rentals",

        "Room Rented",

        ("**Player:** %s\n**Hotel:** %s\n**Room:** %s")
            :format(player, hotel, room),

        Colors.success

    )

end

function Hotel.Webhooks.Booking(player, hotel, room)

    Hotel.Webhooks.Send(

        "bookings",

        "Booking Created",

        ("**Player:** %s\n**Hotel:** %s\n**Room:** %s")
            :format(player, hotel, room),

        Colors.info

    )

end

function Hotel.Webhooks.Complaint(player, hotel, message)

    Hotel.Webhooks.Send(

        "complaints",

        "Complaint Submitted",

        ("**Player:** %s\n**Hotel:** %s\n\n%s")
            :format(player, hotel, message),

        Colors.warning

    )

end

function Hotel.Webhooks.Eviction(player, hotel)

    Hotel.Webhooks.Send(

        "staff",

        "Player Evicted",

        ("**Player:** %s\n**Hotel:** %s")
            :format(player, hotel),

        Colors.error

    )

end

function Hotel.Webhooks.Fine(player, amount, reason)

    Hotel.Webhooks.Send(

        "staff",

        "Fine Issued",

        ("**Player:** %s\n**Amount:** £%s\n**Reason:** %s")
            :format(player, amount, reason),

        Colors.warning

    )

end

----------------------------------------------------------
-- Export
----------------------------------------------------------

exports("SendHotelWebhook", Hotel.Webhooks.Send)
exports("HotelWebhookRental", Hotel.Webhooks.Rental)
exports("HotelWebhookBooking", Hotel.Webhooks.Booking)
exports("HotelWebhookComplaint", Hotel.Webhooks.Complaint)
exports("HotelWebhookEviction", Hotel.Webhooks.Eviction)
exports("HotelWebhookFine", Hotel.Webhooks.Fine)
