# Callbacks, Commands & Events

## lib.callback

Primary client↔server communication pattern. Use whenever a return value is needed.

```lua
-- server - register
lib.callback.register('resourcename:doAction', function(source, param1, param2)
    if not isPlayerLoaded(source) then return false end
    return processAction(source, param1, param2)
end)
```

```lua
-- client - fire with callback
lib.callback('resourcename:doAction', false, function(result)
    if not result then return end
    -- handle result
end, param1, param2)

-- client - await (inside CreateThread or another callback)
local result = lib.callback.await('resourcename:doAction', false, param1, param2)
```

---

## lib.addCommand

```lua
lib.addCommand('commandname', {
    help       = 'Autocomplete description',
    params     = {
        { name = 'targetId', type = 'playerId', help = 'Target player' },
        { name = 'amount',   type = 'number',   help = 'Amount'        },
        { name = 'reason',   type = 'string',   help = 'Reason', optional = true },
    },
    restricted = 'group.admin',
}, function(source, args)
    -- args.targetId, args.amount, args.reason are typed and validated by ox_lib
end)
```

Available param types: `number`, `string`, `boolean`, `playerId`, `playerName`, `item`, `vector3`

---

## Net events - fire-and-forget only

Use only when the server pushes a notification to a client and no return value is needed.
For anything that modifies state, use `lib.callback` instead.

```lua
-- server → specific client
TriggerClientEvent('resourcename:notify', source, message)

-- server → all clients
TriggerClientEvent('resourcename:broadcast', -1, message)

-- client receiver
RegisterNetEvent('resourcename:notify', function(message)
    lib.notify({ title = message, type = 'info' })
end)
```

```lua
-- client → server (no return value needed)
TriggerServerEvent('resourcename:requestSomething')

-- server receiver - always re-read source from the environment
RegisterNetEvent('resourcename:requestSomething', function()
    local source = source
    if not isPlayerLoaded(source) then return end
    doThing(source)
end)
```

---

## Source validation

Call at the top of every callback and net event handler before touching any player data.

```lua
---@param source number
---@return boolean
local function isPlayerLoaded(source)
    return source > 0 and GetPlayerName(source) ~= nil
end
```

Never trust a source ID sent as a payload argument - always read `source` from the server
environment. See `references/security.md` for the full checklist.

---

## TriggerEvent - local (same side, no network)

```lua
-- fire on the same side only; never crosses the network
TriggerEvent('resourcename:localEvent', data)

AddEventHandler('resourcename:localEvent', function(data)
    -- only runs on the side that triggered it
end)
```

Useful for decoupling modules on the same side without a direct function call. Not a substitute
for `lib.callback` - use `TriggerEvent` only when no return value is needed and both sides of
the call are on the same machine.

---

## Exports

Define in fxmanifest, implement in a script, consume from any other resource.

```lua
-- fxmanifest.lua
server_export 'getRoom'
client_export 'isNearRoom'
```

```lua
-- server/_index.lua or the relevant feature file
exports('getRoom', function(roomId)
    return rooms[roomId]
end)
```

```lua
-- client feature file
exports('isNearRoom', function(roomId)
    local room = Config.rooms[roomId]
    if not room then return false end
    return #(GetEntityCoords(cache.ped) - room.coords) < 10.0
end)
```

```lua
-- another resource consuming these
local room      = exports.resourcename:getRoom(roomId)
local isNear    = exports.resourcename:isNearRoom(roomId)
```

Validate inputs inside the export function the same way you would a callback - another resource
calling your export is an untrusted caller.
