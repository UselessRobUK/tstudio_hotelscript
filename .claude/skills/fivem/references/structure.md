# Resource Structure

## File tree

```
resource-name/
├── fxmanifest.lua
├── bridge/
│   ├── _index.lua        -- entry point; requires per-side modules conditionally
│   ├── inventory.lua
│   ├── banking.lua
│   ├── doorlock.lua
│   └── identity.lua      -- getPlayerIdentifier; swap for framework variant
├── configs/
│   ├── shared/
│   │   └── main.lua      -- debug + logging flags, shared constants
│   ├── client/
│   │   └── ui.lua
│   └── server/
│       ├── database.lua
│       └── rules.lua
├── shared/
│   └── debug.lua         -- debugPrint; loaded via shared_scripts before everything else
├── client/
│   ├── _index.lua        -- sole registered client_script; requires what it needs
│   └── <feature>/
│       ├── npc.lua
│       └── rooms.lua
├── server/
│   ├── _index.lua        -- sole registered server_script; requires what it needs
│   ├── logger.lua
│   └── <feature>/
│       ├── payments.lua
│       └── ownership.lua
└── web/                  -- Vite + React; built to web/dist/
    ├── src/
    │   ├── main.tsx
    │   └── App.tsx
    ├── package.json
    └── vite.config.ts
```

SQL schema lives in `bridge/` and is auto-injected by oxmysql on resource start. No loose `.sql`
files shipped to end users.

---

## fxmanifest.lua

Only `_index.lua` files are registered as scripts. Every other Lua file goes in `files {}` so the
client can `require` it on demand without auto-executing it. The server already has filesystem
access to all resource files, so server-side modules do not need `files {}` entries.

```lua
fx_version 'cerulean'
game 'gta5'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/debug.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/_index.lua',
}

client_scripts {
    'client/_index.lua',
}

files {
    -- bridge (required on demand; not auto-executed)
    'bridge/_index.lua',
    'bridge/inventory.lua',
    'bridge/banking.lua',
    'bridge/doorlock.lua',
    'bridge/identity.lua',

    -- client modules (packaged, not auto-executed)
    'client/rooms.lua',
    'client/npc.lua',
    'client/builder.lua',

    -- configs (readable on both sides via require)
    'configs/shared/main.lua',
    'configs/client/ui.lua',
    'configs/server/rules.lua',

    -- NUI
    'web/dist/index.html',
    'web/dist/**/*',
}

ui_page 'web/dist/index.html'

ox_libs {
    'locale',
    'math',
    'table',
}

server_export 'somePublicFunction'
```

---

## _index.lua - explicit module loading

`_index.lua` controls what loads and in what order. Only require what the current side needs.

```lua
-- client/_index.lua
require "configs.shared.main"
require "client.rooms"
require "client.npc"
```

```lua
-- server/_index.lua
require "configs.shared.main"
require "server.logger"
require "server.payments"
require "server.ownership"
require "server.instances"
```

```lua
-- bridge/_index.lua
if IsDuplicityVersion() then
    local inventory = require "bridge.inventory"
    local banking   = require "bridge.banking"
    return {
        playerHasItem = inventory.playerHasItem,
        removeItem    = inventory.removeItem,
        removeMoney   = banking.removeMoney,
        addMoney      = banking.addMoney,
    }
else
    local doorlock = require "bridge.doorlock"
    return {
        setDoorState = doorlock.setDoorState,
    }
end
```

---

## require - config loading

`@ox_lib/init.lua` provides `require` globally. Dot-separated paths map to directory separators
relative to the resource root.

```lua
-- configs/shared/main.lua
return {
    debug       = false,
    logging     = false,
    maxRooms    = 50,
    defaultRate = 200,
}
```

```lua
local Config       = require "configs.server.rules"
local SharedConfig = require "configs.shared.main"
```

Never:
```lua
Config = { ... }   -- global; visible across all scripts in the resource
```
