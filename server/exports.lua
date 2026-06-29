--========================================================--
-- Standalone Hotel Framework
-- server/exports.lua
-- Public API
--========================================================--

Hotel = Hotel or {}

----------------------------------------------------------
-- Hotels
----------------------------------------------------------

exports("GetHotel", function(hotelId)
    return Hotel.GetHotel(hotelId)
end)

exports("GetHotels", function()
    return Config.Hotels or {}
end)

----------------------------------------------------------
-- Rooms
----------------------------------------------------------

exports("GetRoom", function(hotelId, roomId)
    return Hotel.GetRoom(hotelId, tonumber(roomId))
end)

exports("GetRooms", function(hotelId)
    if Hotel.Rooms then
        return Hotel.Rooms.GetAll(hotelId)
    end

    return {}
end)

exports("IsRoomAvailable", function(hotelId, roomId)
    if Hotel.Rooms then
        return Hotel.Rooms.IsAvailable(
            hotelId,
            tonumber(roomId)
        )
    end

    return false
end)

----------------------------------------------------------
-- Rentals
----------------------------------------------------------

exports("CreateRental", function(src, hotelId, roomId, payment)
    return Hotel.CreateRental(
        src,
        hotelId,
        tonumber(roomId),
        payment
    )
end)

exports("CancelRental", function(src, hotelId, roomId)
    return Hotel.CancelRental(
        src,
        hotelId,
        tonumber(roomId)
    )
end)

exports("ExtendRental", function(src, hotelId, roomId, hours, payment)
    return Hotel.ExtendRental(
        src,
        hotelId,
        tonumber(roomId),
        tonumber(hours),
        payment
    )
end)

exports("GetActiveRental", function(src)
    return Hotel.GetActiveRental(src)
end)

----------------------------------------------------------
-- Keys
----------------------------------------------------------

exports("GiveKey", function(src, hotelId, roomId, expires)
    return Hotel.Keys.Give(
        src,
        hotelId,
        tonumber(roomId),
        expires
    )
end)

exports("RemoveKey", function(src, hotelId, roomId)
    return Hotel.Keys.Remove(
        src,
        hotelId,
        tonumber(roomId)
    )
end)

exports("HasKey", function(src, hotelId, roomId)
    return Hotel.Keys.Has(
        Hotel.GetIdentifier(src),
        hotelId,
        tonumber(roomId)
    )
end)

----------------------------------------------------------
-- Instances
----------------------------------------------------------

exports("CreateInstance", function(src, hotelId, roomId)
    return Hotel.Instances.Create(
        src,
        hotelId,
        tonumber(roomId)
    )
end)

exports("JoinInstance", function(src, instanceId)
    return Hotel.Instances.Join(src, instanceId)
end)

exports("LeaveInstance", function(src, instanceId)
    return Hotel.Instances.Leave(src, instanceId)
end)

----------------------------------------------------------
-- Boss
----------------------------------------------------------

exports("IsBoss", function(src, hotelId)
    return Hotel.IsBoss(src, hotelId)
end)

exports("GetDashboard", function(hotelId)
    return Hotel.Boss.GetDashboard(hotelId)
end)

----------------------------------------------------------
-- Employees
----------------------------------------------------------

exports("GetEmployees", function(hotelId)
    return Hotel.Employees.GetEmployees(hotelId)
end)

----------------------------------------------------------
-- Ownership
----------------------------------------------------------

exports("IsOwner", function(src, hotelId)
    return Hotel.Ownership.IsOwner(src, hotelId)
end)

exports("GetOwner", function(hotelId)
    return Hotel.Ownership.GetOwner(hotelId)
end)

----------------------------------------------------------
-- Stash
----------------------------------------------------------

exports("GetStashId", function(hotelId, roomId)
    return Hotel.Stash.GetId(
        hotelId,
        tonumber(roomId)
    )
end)

----------------------------------------------------------
-- Analytics
----------------------------------------------------------

exports("Analytics", function()
    return Hotel.Analytics.Get()
end)

----------------------------------------------------------
-- Notifications
----------------------------------------------------------

exports("Notify", function(src, msg, notifyType)
    Hotel.Notify(src, msg, notifyType)
end)

----------------------------------------------------------
-- Webhooks
----------------------------------------------------------

exports("Webhook", function(...)
    return Hotel.Webhooks.Send(...)
end)

----------------------------------------------------------
-- Builder
----------------------------------------------------------

exports("SaveLayout", function(layout)
    if Hotel.Persistence then
        return Hotel.Persistence.SaveRuntimeHotel(
            layout.id,
            layout
        )
    end

    return false
end)
