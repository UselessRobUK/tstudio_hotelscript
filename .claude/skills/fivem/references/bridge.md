# Bridge Pattern

External dependencies go through bridge modules. Feature code requires the bridge and gets back a
local table - no globals. Swapping a provider means editing one file.

## Structure

```
bridge/
├── _index.lua        -- composes per-side modules, returns unified table
├── inventory.lua     -- server-side
├── banking.lua       -- server-side
├── doorlock.lua      -- client-side
└── identity.lua      -- server-side; player identifier per framework
```

Bridge files are NOT registered as scripts. They live in `files {}` (client) or are just
requireable by the server. `_index.lua` is required by feature files directly.

---

## Each bridge file returns a local module

```lua
-- bridge/inventory.lua
local M = {}

---@param source number
---@param item   string
---@return boolean
function M.playerHasItem(source, item)
    return exports.ox_inventory:GetItem(source, item, nil, true) ~= nil
end

---@param source number
---@param item   string
---@param count  number
---@return boolean
function M.removeItem(source, item, count)
    return exports.ox_inventory:RemoveItem(source, item, count)
end

---@param source number
---@param item   string
---@param count  number
function M.addItem(source, item, count)
    exports.ox_inventory:AddItem(source, item, count)
end

return M
```

```lua
-- bridge/banking.lua
local M = {}

---@param source number
---@param amount number
---@return boolean
function M.removeMoney(source, amount)
    return exports.ox_banking:removeAccountMoney(source, 'bank', amount)
end

---@param source number
---@param amount number
function M.addMoney(source, amount)
    exports.ox_banking:addAccountMoney(source, 'bank', amount)
end

return M
```

```lua
-- bridge/doorlock.lua
local M = {}

---@param doorId number
---@param locked boolean
function M.setDoorState(doorId, locked)
    exports.ox_doorlock:setState(doorId, locked)
end

return M
```

```lua
-- bridge/identity.lua - standalone (source as string)
-- swap this file for qbox/esx variants; see advanced/http-handler.md
local M = {}

---@param source number
---@return string
function M.getPlayerIdentifier(source)
    return tostring(source)
end

return M
```

---

## _index.lua composes and returns

```lua
-- bridge/_index.lua
if IsDuplicityVersion() then
    local inventory = require "bridge.inventory"
    local banking   = require "bridge.banking"
    local identity  = require "bridge.identity"

    return {
        playerHasItem       = inventory.playerHasItem,
        removeItem          = inventory.removeItem,
        addItem             = inventory.addItem,
        removeMoney         = banking.removeMoney,
        addMoney            = banking.addMoney,
        getPlayerIdentifier = identity.getPlayerIdentifier,
    }
else
    local doorlock = require "bridge.doorlock"

    return {
        setDoorState = doorlock.setDoorState,
    }
end
```

---

## Consuming the bridge

Each feature file that needs bridge functions requires `_index` itself. `require` caches the
result so `_index.lua` only executes once per side regardless of how many files require it.

```lua
-- server/feature/payments.lua
local Bridge = require "bridge._index"
local Config = require "configs.server.rules"

lib.callback.register('resourcename:checkout', function(source, roomId)
    if not isPlayerLoaded(source) then return false end

    local removed = Bridge.removeMoney(source, Config.rate)
    if not removed then return false end

    logEvent(source, 'checkout', ('room %d vacated'):format(roomId))
    return true
end)
```

---

## fxmanifest entries for bridge

```lua
-- bridge/_index.lua is NOT in server_scripts or client_scripts
-- server can require it directly; client needs it in files {}

files {
    'bridge/_index.lua',
    'bridge/inventory.lua',
    'bridge/banking.lua',
    'bridge/doorlock.lua',
    'bridge/identity.lua',
}
```

---

## SQL auto-injection

Schema lives in the bridge directory, injected by oxmysql when the resource starts.

```lua
-- bridge/_index.lua (server block, after requires)
if IsDuplicityVersion() then
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `resourcename_rooms` (
            `id`      INT         NOT NULL AUTO_INCREMENT,
            `owner`   VARCHAR(60) NOT NULL,
            `rate`    INT         NOT NULL DEFAULT 0,
            `checkin` BIGINT      NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- return after schema setup
    ...
end
```
