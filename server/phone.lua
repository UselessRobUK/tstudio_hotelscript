local Phone = require "bridge.phone"

RegisterNetEvent("hotel:phone:send", function(title, message)
    Phone.Notify(source, title, message)
end)

exports("SendHotelPhoneMessage", Phone.Notify)
exports("GetHotelPhoneType",     function() return Phone.type end)
