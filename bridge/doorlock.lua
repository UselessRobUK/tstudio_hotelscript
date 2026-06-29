local type = "standalone"

if GetResourceState("ox_doorlock") == "started" then
    type = "ox"
elseif GetResourceState("cd_doorlock") == "started" then
    type = "cd"
elseif GetResourceState("nui_doorlock") == "started" then
    type = "nui"
end

---@param doorId string
---@return boolean
local function Lock(doorId)
    if not doorId then return false end

    if type == "ox" then
        TriggerEvent("ox_doorlock:setState", doorId, true)
        return true
    elseif type == "cd" then
        TriggerEvent("cd_doorlock:SetDoorState", doorId, true)
        return true
    elseif type == "nui" then
        TriggerEvent("nui_doorlock:server:updateState", doorId, true)
        return true
    end

    return true
end

---@param doorId string
---@return boolean
local function Unlock(doorId)
    if not doorId then return false end

    if type == "ox" then
        TriggerEvent("ox_doorlock:setState", doorId, false)
        return true
    elseif type == "cd" then
        TriggerEvent("cd_doorlock:SetDoorState", doorId, false)
        return true
    elseif type == "nui" then
        TriggerEvent("nui_doorlock:server:updateState", doorId, false)
        return true
    end

    return true
end

---@param doorId string
---@param state boolean
---@return boolean
local function Toggle(doorId, state)
    if state then return Lock(doorId) end
    return Unlock(doorId)
end

---@param room table
local function Register(room)
    if type ~= "ox" then return end
    if not room or not room.door then return end

    exports.ox_doorlock:addDoor({
        id      = room.door.id,
        coords  = room.door.coords,
        heading = room.door.heading,
        locked  = true,
        distance = 2.0,
        groups  = {},
    })
end

return {
    type     = type,
    Lock     = Lock,
    Unlock   = Unlock,
    Toggle   = Toggle,
    Register = Register,
}
