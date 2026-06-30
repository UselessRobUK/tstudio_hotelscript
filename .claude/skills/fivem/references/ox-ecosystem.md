# ox Ecosystem Quick Reference

Full docs: https://overextended.dev/docs

---

## ox_lib modules

Import at the top of fxmanifest or load dynamically:

```lua
-- fxmanifest.lua
ox_libs { 'locale', 'math', 'table' }

-- or dynamically in a script
lib.locale()
```

| Module          | What it does                                              |
|-----------------|-----------------------------------------------------------|
| `lib.require`   | Load a Lua module from your resource; no globals          |
| `lib.locale`    | i18n support; reads `locales/<lang>.json`                 |
| `lib.math`      | Extra math helpers (clamp, round, etc.)                   |
| `lib.table`     | Extra table helpers (contains, merge, etc.)               |
| `lib.string`    | Extra string helpers (trim, split, etc.)                  |
| `lib.zones`     | Sphere, box, poly zones with enter/exit callbacks         |
| `lib.points`    | Distance-based point handlers (efficient per-frame check) |
| `lib.marker`    | Draw markers with enter/exit callbacks                    |
| `lib.raycast`   | Simplified raycast helpers                                |
| `lib.streaming` | Async model / anim / texture request wrappers             |
| `lib.waitFor`   | Poll until a condition is met or timeout                  |
| `lib.timer`     | Countdown timers                                          |
| `lib.cron`      | Cron-like scheduled tasks                                 |
| `lib.version`   | Version check against GitHub releases                     |

### lib.zones (client)

```lua
local zone = lib.zones.box({
    coords   = vector3(100.0, 200.0, 30.0),
    size     = vector3(4.0, 4.0, 3.0),
    rotation = 45.0,
    onEnter  = function() end,
    onExit   = function() end,
})
zone:remove()

local poly = lib.zones.poly({
    points  = { vector3(...), vector3(...), vector3(...) },
    thickness = 2.0,
    onEnter = function() end,
    onExit  = function() end,
})
```

### lib.points (client)

More efficient than per-frame distance checks when tracking many world positions.

```lua
local point = lib.points.new({
    coords   = vector3(100.0, 200.0, 30.0),
    distance = 10.0,
    onEnter  = function() end,
    onExit   = function() end,
    nearby   = function(self, distance) end,  -- called per-frame when inside distance
})
point:remove()
```

### lib.streaming (client)

```lua
lib.requestModel(`adder`)           -- blocks until loaded
lib.requestAnimDict('move_m@brave')
lib.requestNamedPtfxAsset('core')
```

### lib.waitFor (shared)

```lua
local ped = lib.waitFor(function()
    local p = PlayerPedId()
    if p ~= 0 then return p end
end, 'Player ped not found', 5000)
```

### cache (shared - auto-available when ox_lib is loaded)

```lua
cache.ped      -- PlayerPedId(), auto-updated
cache.vehicle  -- current vehicle or nil
cache.seat     -- current seat index or nil
cache.resource -- GetCurrentResourceName()
cache.serverId -- GetPlayerServerId(PlayerId())
```

---

## oxmysql

Docs: https://overextended.dev/docs/oxmysql
Import: add `@oxmysql/lib/MySQL.lua` as a `server_script` in fxmanifest.

```lua
-- query: returns array of row tables
local rows = MySQL.query.await('SELECT * FROM rooms WHERE owner = ?', { source })

-- scalar: returns first column of first row
local count = MySQL.scalar.await('SELECT COUNT(*) FROM rooms WHERE owner = ?', { source })

-- single: returns first row as table (or nil)
local room = MySQL.single.await('SELECT * FROM rooms WHERE id = ?', { roomId })

-- update/insert: returns affected rows count
local affected = MySQL.update.await('UPDATE rooms SET rate = ? WHERE id = ?', { rate, roomId })

-- prepare (batch / upsert)
MySQL.prepare.await(
    'INSERT INTO rooms (id, owner, rate) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE owner = VALUES(owner), rate = VALUES(rate)',
    { roomId, source, rate }
)

-- transaction
MySQL.transaction.await({
    { query = 'UPDATE accounts SET balance = balance - ? WHERE owner = ?', values = { amount, source } },
    { query = 'INSERT INTO transactions (owner, amount) VALUES (?, ?)', values = { source, amount } },
})
```

Placeholders: always use `?` for values, never string-interpolate user input into queries.
Column/table names cannot use `?` - validate them against a whitelist if dynamic.

---

## ox_inventory (server exports)

Docs: https://overextended.dev/docs/ox_inventory

```lua
-- check if player has item
exports.ox_inventory:GetItem(source, 'itemName', nil, true)  -- returns count or nil

-- add / remove
exports.ox_inventory:AddItem(source, 'itemName', count)
exports.ox_inventory:RemoveItem(source, 'itemName', count)

-- get full inventory
local inventory = exports.ox_inventory:GetInventory(source, false)

-- slot-based
local item = exports.ox_inventory:GetSlot(source, slotIndex)
```

---

## ox_target (client exports)

Docs: https://overextended.dev/docs/ox_target

```lua
-- add options to a specific entity
exports.ox_target:addLocalEntity(entity, options)

-- remove
exports.ox_target:removeLocalEntity(entity, { 'optionName' })

-- box zone
exports.ox_target:addBoxZone({
    coords   = vector3(x, y, z),
    size     = vector3(w, d, h),
    rotation = heading,
    options  = options,
})

-- sphere zone
exports.ox_target:addSphereZone({
    coords  = vector3(x, y, z),
    radius  = 2.0,
    options = options,
})

-- global model target
exports.ox_target:addModel(`s_m_y_cop`, {
    { name = 'talkToCop', label = 'Talk', onSelect = function() end },
})
```

Option shape:
```lua
{
    name      = 'uniqueId',        -- required; used for removal
    label     = 'Display label',
    icon      = 'fas fa-hand',     -- Font Awesome 6 icon
    distance  = 2.5,               -- max interaction distance (default 2.0)
    canInteract = function(entity) -- optional filter
        return GetEntityHealth(entity) > 0
    end,
    onSelect  = function(data)     -- data.entity, data.coords, data.zone
        -- action
    end,
}
```

---

## ox_doorlock (server)

Docs: https://overextended.dev/docs/ox_doorlock

```lua
-- set door state (server)
exports.ox_doorlock:setState(doorId, true)   -- true = locked, false = unlocked
```

---

## ox_lib ACL (server)

```lua
-- check if player has ace permission
if lib.hasPlayerAce(source, 'resourcename.admin') then ... end

-- register command with ACL restriction
lib.addCommand('adminCmd', { restricted = 'group.admin' }, function(source, args) end)
```
