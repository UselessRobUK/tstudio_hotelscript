local IsServer = IsDuplicityVersion()

local Doors  = {} -- doorId -> { coords, model, heading }
local Locked = {} -- doorId -> boolean (server authoritative)

---@param doorId string
---@return boolean
local function Lock(doorId)
    if not doorId then return false end

    if IsServer then
        Locked[doorId] = true
        TriggerClientEvent("hotel:doorlock:setState", -1, doorId, true)
    end
    return true
end

---@param doorId string
---@return boolean
local function Unlock(doorId)
    if not doorId then return false end

    if IsServer then
        Locked[doorId] = false
        TriggerClientEvent("hotel:doorlock:setState", -1, doorId, false)
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

---@param doorId string
---@return boolean|nil  nil if called client-side
local function IsLocked(doorId)
    if not IsServer then return nil end
    local state = Locked[doorId]
    if state == nil then return true end
    return state
end

---@param room table
local function Register(room)
    if not room or not room.door then return end
    local d = room.door

    Doors[d.id] = { coords = d.coords, model = d.model, heading = d.heading or 0.0 }

    if IsServer then
        if Locked[d.id] == nil then Locked[d.id] = true end
        TriggerClientEvent("hotel:doorlock:registerDoor", -1, d.id, Doors[d.id], Locked[d.id])
    end
end

if IsServer then
    RegisterNetEvent("hotel:doorlock:requestSync", function()
        local src = source
        for doorId, info in pairs(Doors) do
            TriggerClientEvent("hotel:doorlock:registerDoor", src, doorId, info, Locked[doorId] ~= false)
        end
    end)
else
    RegisterNetEvent("hotel:doorlock:registerDoor", function(doorId, info, locked)
        if not info or not info.coords or not info.model then return end
        local hash = GetHashKey(doorId)
        AddDoorToSystem(hash, info.model, info.coords.x, info.coords.y, info.coords.z, false, false, false)
        DoorSystemSetDoorState(hash, locked and 1 or 0, false, false)
    end)

    RegisterNetEvent("hotel:doorlock:setState", function(doorId, locked)
        DoorSystemSetDoorState(GetHashKey(doorId), locked and 1 or 0, false, false)
    end)

    CreateThread(function()
        Wait(2000)
        TriggerServerEvent("hotel:doorlock:requestSync")
    end)
end

return {
    type     = "standalone",
    Lock     = Lock,
    Unlock   = Unlock,
    Toggle   = Toggle,
    Register = Register,
    IsLocked = IsLocked,
}
