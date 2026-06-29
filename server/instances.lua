local Instances = {}

local function Main() return require "server.main" end

---@param hotelId string
---@param roomId number
---@param identifier string
---@return string
local function MakeId(hotelId, roomId, identifier)
    return ("%s:%s:%s"):format(hotelId, roomId, identifier:gsub(":", "_"))
end

---@param src number
---@param hotelId string
---@param roomId number
---@return boolean, string|table
local function Create(src, hotelId, roomId)
    local identifier = Main().GetIdentifier(src)
    if not identifier then return false, "No identifier" end
    if not exports[GetCurrentResourceName()]:HasRoomAccess(src, hotelId, roomId) then return false, "No room access" end

    local room = Main().GetRoom(hotelId, tonumber(roomId))
    if not room then return false, "Invalid room" end

    local instanceId = MakeId(hotelId, roomId, identifier)
    Instances[instanceId] = Instances[instanceId] or {
        id         = instanceId,
        hotel      = hotelId,
        room       = tonumber(roomId),
        owner      = identifier,
        players    = {},
        created_at = os.time(),
    }
    return true, Instances[instanceId]
end

---@param src number
---@param instanceId string
---@return boolean, string?
local function Join(src, instanceId)
    local instance = Instances[instanceId]
    if not instance then return false, "Instance not found" end

    local alreadyInside = false
    for _, player in pairs(instance.players) do
        if player == src then alreadyInside = true break end
    end
    if not alreadyInside then instance.players[#instance.players + 1] = src end

    local room = Main().GetRoom(instance.hotel, instance.room)
    TriggerClientEvent("hotel:enterInstance", src, {
        instanceId   = instance.id,
        hotelId      = instance.hotel,
        roomId       = instance.room,
        coords       = room and (room.inside or room.coords),
        voiceChannel = math.abs(GetHashKey(instance.id)) % 65535,
    })
    return true
end

---@param src number
---@param instanceId string
---@return boolean
local function Leave(src, instanceId)
    local instance = Instances[instanceId]
    if not instance then return false end

    for i = #instance.players, 1, -1 do
        if instance.players[i] == src then table.remove(instance.players, i) end
    end

    local room = Main().GetRoom(instance.hotel, instance.room)
    TriggerClientEvent("hotel:leaveInstance", src, { coords = room and (room.outside or room.entrance) })

    if #instance.players == 0 then Instances[instanceId] = nil end
    return true
end

RegisterNetEvent("hotel:requestEnterInstance", function(hotelId, roomId)
    local src = source
    local ok, instanceOrErr = Create(src, hotelId, tonumber(roomId))
    if not ok then return Main().Notify(src, instanceOrErr or "Could not create instance.", "error") end
    Join(src, instanceOrErr.id)
end)

RegisterNetEvent("hotel:requestLeaveInstance", function(instanceId)
    local src = source
    if not Leave(src, instanceId) then Main().Notify(src, "Could not leave instance.", "error") end
end)

AddEventHandler("playerDropped", function()
    local src = source
    for instanceId, instance in pairs(Instances) do
        for i = #instance.players, 1, -1 do
            if instance.players[i] == src then table.remove(instance.players, i) end
        end
        if #instance.players == 0 then Instances[instanceId] = nil end
    end
end)

exports("CreateHotelInstance", Create)
exports("JoinHotelInstance",   Join)
exports("LeaveHotelInstance",  Leave)

return { Create = Create, Join = Join, Leave = Leave }
