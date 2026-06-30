# State Management, Threads & Natives

## Statebags

Server writes; clients read. Never use a client-readable statebag value as a security gate
in a server handler - re-read from your own server state or DB instead.

```lua
-- server - direct assignment always replicates to all clients
Player(source).state.job   = jobName
Player(source).state.grade = gradeIndex
Entity(vehicle).state.owner = source

-- server - explicitly opt out of replication (server-only)
Player(source).state:set('internalFlag', true, false)

-- client - read
local job   = Player(PlayerId()).state.job
local owner = Entity(vehicle).state.owner

-- watch for changes (client or server)
AddStateBagChangeHandler('job', nil, function(bagName, _, newValue)
    -- bagName is e.g. "player:5"
end)
```

---

## Ephemeral server state

For data that only needs to live while the player is connected. Always clean up in
`playerDropped`.

```lua
---@type table<number, RoomRecord>
local occupiedRooms = {}

---@type table<number, number>
local lastActionTime = {}

AddEventHandler('playerDropped', function()
    occupiedRooms[source]    = nil
    lastActionTime[source]   = nil
end)
```

---

## Threads

```lua
-- repeating thread
CreateThread(function()
    while true do
        Wait(0)     -- 0 = next frame; use the minimum interval that works
        -- per-frame work
    end
end)

-- dynamic tick rate: slow down when nothing to do
CreateThread(function()
    local sleepMs = 1000
    while true do
        Wait(sleepMs)
        local dist = #(GetEntityCoords(PlayerPedId()) - targetCoords)
        sleepMs = dist < 50.0 and 0 or 1000
    end
end)

-- one-shot delay
SetTimeout(3000, function()
    -- runs once after 3 s
end)
```

---

## Caching natives

Natives whose return value is stable between state changes are worth caching. Refresh them on
the relevant event, not every frame.

```lua
local playerPed = cache.ped      -- ox_lib cache module; auto-updated by ox_lib

-- manual cache when ox_lib cache doesn't cover it
local playerServerId = GetPlayerServerId(PlayerId())

-- refresh on respawn
AddEventHandler('gameEventTriggered', function(event, data)
    if event == 'CEventNetworkPlayerCollision' then
        playerPed = PlayerPedId()
    end
end)
```

ox_lib `cache` object (available globally when ox_lib is loaded):

| Key            | Value                          |
|----------------|-------------------------------|
| `cache.ped`    | `PlayerPedId()`               |
| `cache.vehicle`| current vehicle or `nil`      |
| `cache.seat`   | current seat index or `nil`   |
| `cache.resource`| `GetCurrentResourceName()`   |
| `cache.serverId`| `GetPlayerServerId(PlayerId())`|

---

## onResourceStop - cleanup

Zones, points, and entity targets persist until explicitly removed. Clean them up when the
resource stops so they don't linger on a restart.

```lua
-- collect everything that needs cleanup
local activeZones  = {}
local activePoints = {}

-- when creating, store the reference
activeZones[#activeZones + 1]   = lib.zones.sphere({ ... })
activePoints[#activePoints + 1] = lib.points.new({ ... })

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for _, zone  in ipairs(activeZones)  do zone:remove()  end
    for _, point in ipairs(activePoints) do point:remove() end

    exports.ox_target:removeLocalEntity(entity)

    lib.hideTextUI()
    lib.hideContext()
end)
```

Server side - clear ephemeral state tables so a restart begins clean:

```lua
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for k in pairs(occupiedRooms)  do occupiedRooms[k]  = nil end
    for k in pairs(activeSessions) do activeSessions[k] = nil end
end)
```
