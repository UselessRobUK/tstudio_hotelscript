# Logging Reference

---

## Config flags

Both `debug` and `logging` live in the shared config so they can be read on either side,
but `logging` is only acted on server-side (lib.logger is server-only).

```lua
-- configs/shared/main.lua
return {
    debug   = false,   -- enables debugPrint on client + server
    logging = false,   -- enables lib.logger on server (requires ox_lib logger setup)
}
```

---

## debugPrint - shared utility

Define once per side (or in a shared file loaded on both sides). Every feature file that needs
debug output calls this instead of `print`.

```lua
-- shared/debug.lua  (loaded via shared_scripts in fxmanifest)
local Config = require "configs.shared.main"

---@param ... any
local function debugPrint(...)
    if not Config.debug then return end
    local tag = IsDuplicityVersion() and '^5[server]^7' or '^6[client]^7'
    print(tag, ...)
end
```

Because it's a local in a shared script, it's available to every script loaded after it in the
same side. Add `shared/debug.lua` before feature scripts in fxmanifest:

```lua
-- fxmanifest.lua
shared_scripts {
    '@ox_lib/init.lua',
    'shared/debug.lua',   -- before everything else that uses debugPrint
}
```

Usage:

```lua
debugPrint('player checked in', source, roomId)
debugPrint('coords:', GetEntityCoords(PlayerPedId()))
```

---

## lib.logger - production logging (server only)

`lib.logger` ships structured log events to an external service (Datadog, Grafana Loki, etc.)
configured via ox_lib's convars in `server.cfg`. The resource itself only needs to call the
function; ox_lib handles the transport.

ox_lib logger docs: https://overextended.dev/docs/ox_lib/Logger

```
# server.cfg - ox_lib logger configuration (all handled outside the resource)
setr ox:logger "datadog"
setr ox:loggerUrl "https://logs.example.com"
setr ox:loggerToken "your-token"
```

### Wrapper with toggle

Wrap `lib.logger` so it respects the resource's own `logging` config flag and centralises the
call signature.

```lua
-- server/logger.lua
local Config = require "configs.shared.main"

---@param source  number   player source; 0 for system events
---@param event   string   event identifier, e.g. 'checkin' or 'payment'
---@param message string   human-readable description
local function logEvent(source, event, message)
    if not Config.logging then return end
    lib.logger(source, event, message)
end
```

Load it before feature scripts:

```lua
-- fxmanifest.lua
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/init.lua',
    'bridge/inventory.lua',
    'bridge/banking.lua',
    'server/logger.lua',   -- before feature scripts
    'server/**/*.lua',
}
```

### Usage in feature scripts

```lua
-- server/feature/payments.lua
lib.callback.register('resourcename:checkout', function(source, roomId)
    if not isValidSource(source) then return false end

    local removed = Bridge.removeItem(source, 'cash', Config.rate)
    if not removed then
        logEvent(source, 'checkout_failed', ('insufficient funds for room %d'):format(roomId))
        return false
    end

    logEvent(source, 'checkout', ('checked out of room %d'):format(roomId))
    return true
end)
```

---

## ox_lib locale - one-time init

`lib.locale()` initialises the locale module. Call it once per side, or declare the module in
`ox_libs` in fxmanifest to initialise it automatically.

```lua
-- fxmanifest.lua - automatic init (preferred)
ox_libs {
    'locale',
}
```

```lua
-- or: call once at the top of one server file and once in one client file
lib.locale()
```

Then anywhere in the same side:

```lua
print(locale('room_checkin_success'))
```

Locale files go in `locales/<lang>.json`:

```json
{
    "room_checkin_success": "You have checked in.",
    "room_checkout_fail":   "Could not check out: %s"
}
```

Format with arguments:

```lua
lib.notify({ title = locale('room_checkout_fail', reason), type = 'error' })
```

---

## Summary: what goes where

| Concern              | Tool          | Side          | Toggle           |
|----------------------|---------------|---------------|------------------|
| Dev-time tracing     | `debugPrint`  | client+server | `Config.debug`   |
| Production audit log | `lib.logger`  | server only   | `Config.logging` |
| Player-facing text   | `locale()`    | client+server | n/a              |
| ox_lib transport cfg | convars       | server.cfg    | per-service      |
