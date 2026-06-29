--========================================================--
-- Standalone Hotel Framework
-- server/phone.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Phone = Hotel.Phone or {}

Hotel.Phone.Type = "standalone"

if GetResourceState("qb-phone") == "started" then
    Hotel.Phone.Type = "qb-phone"
elseif GetResourceState("qs-smartphone") == "started" then
    Hotel.Phone.Type = "qs-smartphone"
elseif GetResourceState("gksphone") == "started" then
    Hotel.Phone.Type = "gksphone"
elseif GetResourceState("lb-phone") == "started" then
    Hotel.Phone.Type = "lb-phone"
end

local function Send(src, title, message)
    title = title or "Hotel"
    message = message or ""

    if Hotel.Phone.Type == "qb-phone" then
        TriggerClientEvent("qb-phone:client:CustomNotification", src, title, message, "fas fa-hotel")
        return true
    end

    if Hotel.Phone.Type == "qs-smartphone" then
        TriggerClientEvent("qs-smartphone:client:notify", src, title, message)
        return true
    end

    if Hotel.Phone.Type == "gksphone" then
        TriggerClientEvent("gksphone:notifi", src, { title = title, message = message })
        return true
    end

    if Hotel.Phone.Type == "lb-phone" then
        exports["lb-phone"]:SendNotification(src, {
            app = "Messages",
            title = title,
            content = message
        })
        return true
    end

    Hotel.Notify(src, ("[%s] %s"):format(title, message), "inform")
    return true
end

RegisterNetEvent("hotel:phone:send", function(title, message)
    Send(source, title, message)
end)

exports("SendHotelPhoneMessage", Send)
exports("GetHotelPhoneType", function()
    return Hotel.Phone.Type
end)
