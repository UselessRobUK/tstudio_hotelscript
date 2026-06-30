# NUI → Server Direct (client-skipping)

Eliminates the round-trip: **NUI → client → server → client → NUI**
Replaces it with: **NUI → server → NUI**

NUI fetches directly to the FiveM server's HTTP port. The server responds via `SetHttpHandler`
(see `advanced/http-handler.md`). The client is not involved after the initial handshake.

---

## How it works

1. Player fully loads → server generates a token tied to that player's source
2. Server sends `{ token, endpoint, playerId }` to the client
3. Client passes all three to the NUI via `SendNUIMessage`
4. NUI attaches `X-Token` + `X-Player-Id` headers to every direct request
5. Server validates both headers before routing
6. Player drops → server revokes the token

---

## Server - token assignment

`playerJoining` fires before the framework has populated the player's data, so framework-based
identity bridges (citizenid, charid) won't be ready yet. Use a framework-specific "player
loaded" event, or `playerConnecting` deferrals if you need it earlier. For the standalone
identity bridge (source as string) `playerJoining` is fine.

```lua
-- server/_index.lua
local Http   = require "server.http"    -- must be required first
local Bridge = require "bridge._index"
local Config = require "configs.server.main"

-- standalone: playerJoining is fine
-- qbox:  listen to 'QBCore:Server:PlayerLoaded' instead
-- esx:   listen to 'esx:playerLoaded' instead
AddEventHandler('playerJoining', function()
    local source = source
    local token  = Http.assignToken(source)

    TriggerClientEvent('resourcename:init', source, {
        token    = token,
        endpoint = ('%s/%s'):format(Config.serverUrl, GetCurrentResourceName()),
        playerId = Bridge.getPlayerIdentifier(source),
    })
end)

AddEventHandler('playerDropped', function()
    Http.revokeToken(source)
end)
```

`Config.serverUrl` lives in `configs/server/main.lua` - it is a server-only concern. The
client and NUI receive the URL pushed from the server; they never read the config directly.

```lua
-- configs/server/main.lua
return {
    logging   = false,
    serverUrl = 'http://your.server.ip:30120',   -- no trailing slash; game port
}
```

For local dev use `http://localhost:30120`.

---

## Load order in server/_index.lua

`server/http.lua` registers `SetHttpHandler` and owns the route registry. It must be required
before any feature file that calls `Http.post()`.

```lua
-- server/_index.lua
local Http   = require "server.http"       -- first
local Bridge = require "bridge._index"
local Config = require "configs.server.main"

-- token assignment handler (above) goes here, after Http is loaded

require "server.logger"
require "server.feature.checkout"          -- calls Http.post('/checkout', ...) internally
require "server.feature.ownership"
```

---

## Client - receive and forward to NUI

```lua
RegisterNetEvent('resourcename:init', function(initData)
    SendNUIMessage({
        action   = 'init',
        endpoint = initData.endpoint,
        token    = initData.token,
        playerId = initData.playerId,
    })
end)
```

The client does nothing else. It is not in the request path after this point.

---

## NUI - store config and fetch

```ts
type HttpConfig = {
    endpoint: string   -- e.g. 'http://1.2.3.4:30120/resourcename'
    token:    string
    playerId: string
}

let httpConfig: HttpConfig | null = null

window.addEventListener('message', ({ data }) => {
    if (data.action === 'init') {
        httpConfig = {
            endpoint: data.endpoint,
            token:    data.token,
            playerId: data.playerId,
        }
    }
})

async function serverFetch<T>(path: string, body: unknown): Promise<T> {
    if (!httpConfig) throw new Error('http config not received yet')

    const resp = await fetch(`${httpConfig.endpoint}${path}`, {
        method:  'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-Token':      httpConfig.token,
            'X-Player-Id':  httpConfig.playerId,
        },
        body: JSON.stringify(body),
    })

    if (!resp.ok) throw new Error(`server responded ${resp.status}`)
    return resp.json()
}
```

Usage anywhere in the React app:

```tsx
const handleCheckout = async () => {
    const result = await serverFetch<{ success: boolean; reason?: string }>('/checkout', {
        roomId: selectedRoom,
    })
    if (!result.success) {
        showError(result.reason)
        return
    }
    closeUI()
}
```

---

## Comparison

| | Standard NUI | Direct HTTP |
|---|---|---|
| Flow | NUI → client → server → client → NUI | NUI → server → NUI |
| Latency | 2× round-trip | 1× round-trip |
| Client involvement | Every request | Init only |
| Auth | Implicit (FiveM NUI callback) | Token + player ID header |
| Good for | Simple one-off actions | High-frequency UI, real-time data |

---

## Security notes

- Token is generated server-side; never derived from anything the client sends
- Token is revoked immediately on `playerDropped`
- `X-Player-Id` is verified against the token's owner via `Bridge.getPlayerIdentifier`
- Route handlers receive a validated `source` - apply the full checklist from `references/security.md`
- `Config.serverUrl` is server-only; never expose it via a client event or NUI message beyond
  what's needed to construct the endpoint string
