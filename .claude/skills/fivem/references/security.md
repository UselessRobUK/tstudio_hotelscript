# Security Reference

A checklist of questions to ask for every callback, net event, and export handler.
If any answer is "no" or "not yet", fix it before shipping.

---

## The core question

**Does the server independently verify every assumption before acting?**

The client is user-controlled. Any value it sends - amounts, IDs, coords, item names,
job names - must be treated as untrusted input.

---

## Checklist

### Source

- [ ] Is `source` a real connected player? (`GetPlayerName(source) ~= nil`)
- [ ] Is `source` the same player who owns the thing being acted on? (never let player A act on player B's data by sending B's ID)
- [ ] Have I re-read `source` from the server environment rather than trusting a client-sent ID?

```lua
-- wrong: client sends its own source to identify itself
RegisterNetEvent('resourcename:doThing', function(claimedSource)
    processFor(claimedSource)  -- attacker can send any source
end)

-- right: source is always the net ID of the sender, read server-side
RegisterNetEvent('resourcename:doThing', function()
    local source = source
    processFor(source)
end)
```

### Amounts (money, items, quantities)

- [ ] Is the amount **never** sent by the client?
- [ ] Is the amount derived server-side (from config, database, or game state)?
- [ ] Is the amount validated against min/max bounds before use?

```lua
-- wrong
lib.callback.register('shop:buy', function(source, itemName, amount)
    charge(source, amount)  -- client decides the price
end)

-- right
lib.callback.register('shop:buy', function(source, itemName)
    local price = Config.items[itemName]
    if not price then return false end
    return charge(source, price)
end)
```

### Job / permission

- [ ] Is the player's job/grade read from the server (statebag set by server, or DB query)?
- [ ] Is job checked **server-side** in every handler that gates on it?
- [ ] Can a player fake their job by triggering the event without the UI?

```lua
-- wrong: client sends its own job
RegisterNetEvent('police:action', function(job)
    if job == 'police' then doThing(source) end
end)

-- right: server reads job independently
RegisterNetEvent('police:action', function()
    local source = source
    local job = Player(source).state.job
    if job ~= 'police' then return end
    doThing(source)
end)
```

### Item / inventory

- [ ] Does the server confirm the player **has the item** before consuming it?
- [ ] Is the item removed **before** the reward is given, not after?
- [ ] Is there a race condition where the callback could be triggered twice before the item is removed?

```lua
-- wrong: give first, remove later (window for duplicate exploits)
local ok = giveReward(source)
if ok then removeItem(source, 'key', 1) end

-- right: remove first, give only on success
local removed = exports.ox_inventory:RemoveItem(source, 'key', 1)
if not removed then return false end
giveReward(source)
```

### Cooldowns

- [ ] Is there a server-side cooldown preventing the action from being spammed?
- [ ] Is the cooldown stored server-side, not client-side?

```lua
---@type table<number, number>
local lastActionTime = {}

lib.callback.register('resourcename:action', function(source)
    local now = os.time()
    if (lastActionTime[source] or 0) + 30 > now then return false end
    lastActionTime[source] = now
    return doAction(source)
end)

AddEventHandler('playerDropped', function()
    lastActionTime[source] = nil
end)
```

### Coordinates / positions

- [ ] If the client sends coords (e.g. "spawn here"), are they validated against a whitelist or range?
- [ ] Is the player actually near the coords they claim to be at?

```lua
lib.callback.register('resourcename:interactAt', function(source, coords)
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local distance = #(playerCoords - coords)
    if distance > 10.0 then return false end
    processInteraction(source, coords)
end)
```

### Entity ownership

- [ ] Is entity network ownership verified server-side before allowing actions on an entity?
- [ ] Are entities that should be server-controlled spawned server-side?

```lua
-- client cannot be trusted to own the entity it claims to own
-- verify on the server
local owner = NetworkGetEntityOwner(entityHandle)
if owner ~= source then return end
```

### Exports (public API surface)

- [ ] Do exported functions validate their caller if the action is sensitive?
- [ ] Is the export restricted to trusted resources via ACL where applicable?

```lua
-- server export
exports('giveReward', function(source, amount)
    if not isValidSource(source) then return end
    if type(amount) ~= 'number' or amount <= 0 or amount > 10000 then return end
    doGiveReward(source, amount)
end)
```

### SQL

- [ ] Are all query values passed as `?` placeholders, never interpolated into the query string?
- [ ] Are column/table names that must be dynamic validated against a hardcoded whitelist?

```lua
-- wrong
MySQL.query.await('SELECT * FROM ' .. tableName .. ' WHERE id = ' .. source)

-- right
local allowedTables = { rooms = true, vehicles = true }
if not allowedTables[tableName] then return end
MySQL.query.await('SELECT * FROM ' .. tableName .. ' WHERE id = ?', { source })
```

### Statebags

- [ ] Are statebags that hold trusted values (job, grade, permissions) only written server-side?
- [ ] Is `replicate = true` only used when clients genuinely need to read the value?

```lua
-- server only; never allow the client to set these
Player(source).state:set('job', jobName, true)
Player(source).state:set('grade', gradeIndex, true)
```

Clients can write their own statebags by default in some OneSync configurations. If sensitive
values must be statebag-readable but not client-writable, set them only from server scripts and
never trust a client-readable statebag value in a server-side security check - re-read from your
own server state or database instead.

### Admin / restricted commands

- [ ] Is the command restricted via `lib.addCommand` `restricted` field or ACE?
- [ ] Is the restriction enforced server-side, not just hidden client-side?

```lua
lib.addCommand('giveitem', {
    restricted = 'group.admin',   -- ox_lib enforces this server-side
    params     = {
        { name = 'targetId', type = 'playerId' },
        { name = 'item',     type = 'string'   },
        { name = 'count',    type = 'number'   },
    },
}, function(source, args)
    if args.count > 100 then return end  -- secondary bound check
    exports.ox_inventory:AddItem(args.targetId, args.item, args.count)
end)
```

---

## Red flags in a code review

Any of these in a server handler means the handler is likely exploitable:

- Client sends a money amount and the server uses it directly
- `TriggerServerEvent` handler does not re-read `source` from the server environment
- Item is given before it is removed
- Job/grade is read from a client-sent argument
- No cooldown on anything that gives value
- SQL query string is built with `..` concatenation
- Client sends a target player's source ID and the server acts on it without verifying relationship
- Statebag value used as a security gate in a server handler
