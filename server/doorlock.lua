local function Main()    return require "server.main" end
local function KeysMod()  return require "server.keys" end
local DoorLock = require "bridge.doorlock"

RegisterNetEvent("hotel:doorlock:interact", function(hotelId, roomId)
    local src        = source
    local identifier = Main().GetIdentifier(src)
    if not identifier then return end

    roomId = tonumber(roomId)
    local room = Main().GetRoom(hotelId, roomId)
    if not room or not room.door then return end

    if not KeysMod().Has(identifier, hotelId, roomId) then
        return Main().Notify(src, "You need a key for this room.", "error")
    end

    local doorId = room.door.id
    local locked = DoorLock.IsLocked(doorId)
    if locked == nil then locked = true end

    DoorLock.Toggle(doorId, not locked)
    Main().Notify(src, locked and "Door unlocked." or "Door locked.", "success")
end)
