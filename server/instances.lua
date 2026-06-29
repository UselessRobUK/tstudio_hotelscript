--========================================================--
-- Standalone Hotel Framework
-- server/instances.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Instances = Hotel.Instances or {}

local function Notify(src, msg, t)
    Hotel.Notify(src, msg, t or "inform")
end

local function MakeInstanceId(hotelId, roomId, identifier)
    return ("%s:%s:%s"):format(hotelId, roomId, identifier:gsub(":", "_"))
end

function Hotel.Instances.Create(src, hotelId, roomId)
    local identifier = Hotel.GetIdentifier(src)
    if not identifier then return false, "No identifier" end

    if not exports[GetCurrentResourceName()]:HasRoomAccess(src, hotelId, roomId) then
        return false, "No room access"
    end

    local room = Hotel.GetRoom(hotelId, tonumber(roomId))
    if not room then return false, "Invalid room" end

    local instanceId = MakeInstanceId(hotelId, roomId, identifier)

    Hotel.Instances[instanceId] = Hotel.Instances[instanceId] or {
        id = instanceId,
        hotel = hotelId,
        room = tonumber(roomId),
        owner = identifier,
        players = {},
        created_at = os.time()
    }

    return true, Hotel.Instances[instanceId]
end

function Hotel.Instances.Join(src, instanceId)
    local instance = Hotel.Instances[instanceId]
    if not instance then return false, "Instance not found" end

    local alreadyInside = false

    for _, player in pairs(instance.players) do
        if player == src then
            alreadyInside = true
            break
        end
    end

    if not alreadyInside then
        instance.players[#instance.players + 1] = src
    end

    local room = Hotel.GetRoom(instance.hotel, instance.room)

    TriggerClientEvent("hotel:enterInstance", src, {
        instanceId = instance.id,
        hotelId = instance.hotel,
        roomId = instance.room,
        coords = room and (room.inside or room.coords),
        voiceChannel = math.abs(GetHashKey(instance.id)) % 65535
    })

    return true
end

function Hotel.Instances.Leave(src, instanceId)
    local instance = Hotel.Instances[instanceId]
    if not instance then return false end

    for i = #instance.players, 1, -1 do
        if instance.players[i] == src then
            table.remove(instance.players, i)
        end
    end

    local room = Hotel.GetRoom(instance.hotel, instance.room)

    TriggerClientEvent("hotel:leaveInstance", src, {
        coords = room and (room.outside or room.entrance)
    })

    if #instance.players == 0 then
        Hotel.Instances[instanceId] = nil
    end

    return true
end

RegisterNetEvent("hotel:requestEnterInstance", function(hotelId, roomId)
    local src = source

    local ok, instanceOrErr = Hotel.Instances.Create(src, hotelId, tonumber(roomId))
    if not ok then
        return Notify(src, instanceOrErr or "Could not create instance.", "error")
    end

    Hotel.Instances.Join(src, instanceOrErr.id)
end)

RegisterNetEvent("hotel:requestLeaveInstance", function(instanceId)
    local src = source

    if not Hotel.Instances.Leave(src, instanceId) then
        Notify(src, "Could not leave instance.", "error")
    end
end)

AddEventHandler("playerDropped", function()
    local src = source

    for instanceId, instance in pairs(Hotel.Instances) do
        for i = #instance.players, 1, -1 do
            if instance.players[i] == src then
                table.remove(instance.players, i)
            end
        end

        if #instance.players == 0 then
            Hotel.Instances[instanceId] = nil
        end
    end
end)

exports("CreateHotelInstance", Hotel.Instances.Create)
exports("JoinHotelInstance", Hotel.Instances.Join)
exports("LeaveHotelInstance", Hotel.Instances.Leave)
