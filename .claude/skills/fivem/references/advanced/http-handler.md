# SetHttpHandler - Reusable HTTP Router

Server-side only. URL format: `http://<serverIp>:<port>/<resourceName>/<path>`

Native docs: https://docs.fivem.net/natives/?_0xF5C6330C=

**Critical**: the request body is NOT on the request object. You must call
`request.setDataHandler(fn)` to receive it asynchronously. Any code that reads `request.body`
directly is wrong.

`SetHttpHandler` can only be called once per resource. This module wraps it with a route
registry and token-based auth. Require it before any file that registers routes.

---

## server/http.lua

```lua
local M = {}

---@type table<string, fun(source: number, body: table): table>
local routes = {}

---@type table<string, number>
local tokenToSource = {}

---@type table<number, string>
local sourceToToken = {}

---@param path    string    e.g. '/checkout'
---@param handler fun(source: number, body: table): table
function M.post(path, handler)
    routes[path] = handler
end

---@param source number
---@return string
function M.assignToken(source)
    local existing = sourceToToken[source]
    if existing then tokenToSource[existing] = nil end

    local token = ('%08x%08x%08x%08x'):format(
        math.random(0, 0xffffffff),
        math.random(0, 0xffffffff),
        math.random(0, 0xffffffff),
        math.random(0, 0xffffffff)
    )

    tokenToSource[token]  = source
    sourceToToken[source] = token
    return token
end

---@param source number
function M.revokeToken(source)
    local token = sourceToToken[source]
    if not token then return end
    tokenToSource[token]  = nil
    sourceToToken[source] = nil
end

---@param source number
---@return string | nil
function M.getToken(source)
    return sourceToToken[source]
end

local function respond(response, statusCode, data)
    response.writeHead(statusCode, {
        ['Content-Type']                = 'application/json',
        ['Access-Control-Allow-Origin'] = '*',
    })
    response.send(json.encode(data))
end

SetHttpHandler(function(request, response)
    if request.method == 'OPTIONS' then
        response.writeHead(204, {
            ['Access-Control-Allow-Origin']  = '*',
            ['Access-Control-Allow-Headers'] = 'Content-Type, X-Token, X-Player-Id',
            ['Access-Control-Allow-Methods'] = 'POST, OPTIONS',
        })
        response.send()
        return
    end

    local token    = request.headers['x-token']
    local playerId = request.headers['x-player-id']

    if not token or not playerId then
        respond(response, 401, { error = 'missing_headers' })
        return
    end

    local source = tokenToSource[token]
    if not source then
        respond(response, 401, { error = 'invalid_token' })
        return
    end

    if Bridge.getPlayerIdentifier(source) ~= playerId then
        respond(response, 403, { error = 'forbidden' })
        return
    end

    local handler = routes[request.path]
    if not handler then
        respond(response, 404, { error = 'not_found' })
        return
    end

    request.setDataHandler(function(rawBody)
        local ok, body = pcall(json.decode, rawBody)
        local result   = handler(source, ok and body or {})
        respond(response, 200, result)
    end)
end)

return M
```

`Bridge.getPlayerIdentifier` comes from `bridge/identity.lua` via `bridge/_index.lua`.
See `references/bridge.md` for the standalone, QBox, and ESX variants.

---

## Registering routes

`server/http.lua` must be required before any file that calls `Http.post()` - it owns the
route table and `SetHttpHandler`. Require it first in `server/_index.lua`.

```lua
-- server/_index.lua
local Http = require "server.http"      -- must be first

require "server.logger"
require "server.feature.checkout"       -- registers routes via Http.post
require "server.feature.ownership"
```

```lua
-- server/feature/checkout.lua
local Http   = require "server.http"
local Config = require "configs.server.rules"

Http.post('/checkout', function(source, body)
    if not isPlayerLoaded(source) then
        return { success = false, reason = 'not_loaded' }
    end

    local roomId = tonumber(body.roomId)
    if not roomId or not rooms[roomId] then
        return { success = false, reason = 'invalid_room' }
    end

    local removed = Bridge.removeMoney(source, Config.rate)
    if not removed then
        return { success = false, reason = 'insufficient_funds' }
    end

    rooms[roomId]:checkout()
    logEvent(source, 'checkout', ('room %d'):format(roomId))
    return { success = true }
end)
```

Because `require` caches modules, calling `require "server.http"` in a feature file returns
the same `M` table that was initialized in `_index.lua`. `Http.post` always writes into the
same `routes` table.
