# FiveM Natives Reference

Full reference: https://docs.fivem.net/natives/
Filter by API set (client / server / shared) and language (lua / js / c#).

---

## Key namespaces and what lives in them

| Namespace    | Examples                                                  |
|--------------|-----------------------------------------------------------|
| PLAYER       | GetPlayerPed, GetPlayerName, GetPlayerCoords              |
| ENTITY       | GetEntityCoords, SetEntityCoords, DeleteEntity, DoesEntityExist |
| PED          | CreatePed, SetPedArmour, TaskGoToCoordAnyMeans            |
| VEHICLE      | CreateVehicle, SetVehicleEngineOn, GetVehicleNumberPlateText |
| NETWORK      | NetworkGetEntityOwner, NetworkDoesEntityExistWithNetworkId |
| CAM          | CreateCam, SetCamActive, RenderScriptCams                 |
| UI / GRAPHICS | DrawText, DrawRect, GetScreenCoordFromWorldCoord          |
| CONTROLS     | IsControlJustReleased, DisableControlAction               |
| AUDIO        | PlaySoundFrontend, PlaySoundFromEntity                    |
| OBJECT       | CreateObject, PlaceObjectOnGroundProperly                 |
| STREAMING    | RequestModel, HasModelLoaded, SetModelAsNoLongerNeeded    |
| BRAIN / TASK | TaskLeaveVehicle, TaskCombatPed, ClearPedTasks            |

---

## Common client patterns

### Player ped + coords

```lua
local ped    = PlayerPedId()
local coords = GetEntityCoords(ped)
local heading = GetEntityHeading(ped)
```

### Model streaming (always request before use, release after)

```lua
local modelHash = `adder`
RequestModel(modelHash)
while not HasModelLoaded(modelHash) do Wait(0) end

local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, false)

SetModelAsNoLongerNeeded(modelHash)
```

### Entity coords + heading

```lua
SetEntityCoords(entity, x, y, z, false, false, false, false)
SetEntityHeading(entity, heading)
```

### Disable controls in a loop

```lua
CreateThread(function()
    while uiOpen do
        DisableAllControlActions(0)
        Wait(0)
    end
end)
```

### Distance check

```lua
local playerCoords = GetEntityCoords(PlayerPedId())
local targetCoords = vector3(100.0, 200.0, 30.0)
local distance = #(playerCoords - targetCoords)
if distance < 5.0 then ... end
```

### Draw text (per-frame, call inside CreateThread)

```lua
SetTextFont(0)
SetTextProportional(true)
SetTextScale(0.4, 0.4)
SetTextColour(255, 255, 255, 215)
SetTextDropShadow()
SetTextEntry('STRING')
AddTextComponentString('Hello world')
DrawText(0.5, 0.5)
```

---

## Common server patterns

### Iterate connected players

```lua
for _, playerId in ipairs(GetPlayers()) do
    local name = GetPlayerName(playerId)
end
```

### Get server ID from identifier

```lua
---@param license string
---@return number | nil
local function findPlayerByLicense(license)
    for _, playerId in ipairs(GetPlayers()) do
        for i = 0, GetNumPlayerIdentifiers(playerId) - 1 do
            if GetPlayerIdentifier(playerId, i) == 'license:' .. license then
                return tonumber(playerId)
            end
        end
    end
end
```

### Kick / drop player

```lua
DropPlayer(source, 'Reason shown to player')
```

### OneSync: get entity owner

```lua
local owner = NetworkGetEntityOwner(entityNetId)
```

---

## Statebag patterns

```lua
-- server: set, replicate = true sends to all clients
Player(source).state:set('key', value, true)
Entity(entityHandle).state:set('key', value, true)

-- client: read
local value = Player(PlayerId()).state.key
local value = Entity(entity).state.key

-- client: watch for changes
AddStateBagChangeHandler('key', nil, function(bagName, _, value)
    print(bagName, value)
end)
```

---

## Hash literals (Jenkins)

FiveM's Lua runtime supports compile-time hash generation using backticks. Zero runtime overhead.

```lua
local vehicleHash = `adder`               -- same as GetHashKey('adder')
local weaponHash  = `WEAPON_PISTOL`
local pedHash     = `a_m_y_skater_01`

if GetEntityModel(vehicle) == `buzzard` then ... end
```

---

## Vectors

Vectors are first-class types in CfxLua.

```lua
local pos  = vector3(100.0, 200.0, 30.0)
local rot  = vector3(0.0, 0.0, 90.0)
local dist = #(pos - GetEntityCoords(PlayerPedId()))
```

---

## Events reference

Key built-in events:

| Event                   | Side   | Notes                          |
|-------------------------|--------|--------------------------------|
| `playerConnecting`      | server | cancellable; use deferrals     |
| `playerDropped`         | server | source is accessible           |
| `onResourceStart`       | both   | receives resourceName          |
| `onResourceStop`        | both   | receives resourceName          |
| `onClientResourceStart` | client | receives resourceName          |
| `gameEventTriggered`    | client | low-level game events          |
