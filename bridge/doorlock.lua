--========================================================--
-- Standalone Hotel Framework
-- bridge/doorlock.lua
--========================================================--

Bridge = Bridge or {}
Bridge.Doorlock = Bridge.Doorlock or {}

----------------------------------------------------------
-- Detect Installed Resource
----------------------------------------------------------

Bridge.Doorlock.Type = "standalone"

if GetResourceState("ox_doorlock") == "started" then
    Bridge.Doorlock.Type = "ox"

elseif GetResourceState("cd_doorlock") == "started" then
    Bridge.Doorlock.Type = "cd"

elseif GetResourceState("nui_doorlock") == "started" then
    Bridge.Doorlock.Type = "nui"

end

----------------------------------------------------------
-- Lock Door
----------------------------------------------------------

function Bridge.Doorlock.Lock(doorId)

    if not doorId then
        return false
    end

    if Bridge.Doorlock.Type == "ox" then

        TriggerEvent("ox_doorlock:setState", doorId, true)
        return true

    elseif Bridge.Doorlock.Type == "cd" then

        TriggerEvent("cd_doorlock:SetDoorState", doorId, true)
        return true

    elseif Bridge.Doorlock.Type == "nui" then

        TriggerEvent("nui_doorlock:server:updateState", doorId, true)
        return true

    end

    return true

end

----------------------------------------------------------
-- Unlock Door
----------------------------------------------------------

function Bridge.Doorlock.Unlock(doorId)

    if not doorId then
        return false
    end

    if Bridge.Doorlock.Type == "ox" then

        TriggerEvent("ox_doorlock:setState", doorId, false)
        return true

    elseif Bridge.Doorlock.Type == "cd" then

        TriggerEvent("cd_doorlock:SetDoorState", doorId, false)
        return true

    elseif Bridge.Doorlock.Type == "nui" then

        TriggerEvent("nui_doorlock:server:updateState", doorId, false)
        return true

    end

    return true

end

----------------------------------------------------------
-- Toggle Door
----------------------------------------------------------

function Bridge.Doorlock.Toggle(doorId, state)

    if state then
        return Bridge.Doorlock.Lock(doorId)
    end

    return Bridge.Doorlock.Unlock(doorId)

end

----------------------------------------------------------
-- Register Door
----------------------------------------------------------

function Bridge.Doorlock.Register(room)

    if Bridge.Doorlock.Type ~= "ox" then
        return
    end

    if not room or not room.door then
        return
    end

    exports.ox_doorlock:addDoor({

        id = room.door.id,

        coords = room.door.coords,

        heading = room.door.heading,

        locked = true,

        distance = 2.0,

        groups = {}

    })

end

----------------------------------------------------------
-- Register All Hotel Doors
----------------------------------------------------------

CreateThread(function()

    Wait(3000)

    for _, hotel in pairs(Config.Hotels or {}) do

        local rooms = hotel.rooms or Config.Rooms[hotel.id] or {}

        for _, room in pairs(rooms) do

            Bridge.Doorlock.Register(room)

        end

    end

end)

----------------------------------------------------------
-- Exports
----------------------------------------------------------

exports("DoorlockLock", Bridge.Doorlock.Lock)

exports("DoorlockUnlock", Bridge.Doorlock.Unlock)

exports("DoorlockToggle", Bridge.Doorlock.Toggle)

exports("DoorlockRegister", Bridge.Doorlock.Register)

exports("DoorlockType", function()

    return Bridge.Doorlock.Type

end)
