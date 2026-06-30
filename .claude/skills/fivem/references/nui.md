# NUI - Vite + React

`web/` is a standard Vite React project. fxmanifest points to `web/dist/index.html`.

## vite.config.ts

```ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
    plugins: [react()],
    base: './',
    build: { outDir: 'dist' },
})
```

## Lua → NUI

```lua
SendNUIMessage({ action = 'open', data = { balance = 500, items = itemList } })
SetNuiFocus(true, true)

-- close
SetNuiFocus(false, false)
SendNUIMessage({ action = 'close' })
```

## NUI → Lua (client handlers)

```lua
RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('checkout', function(data, cb)
    local result = lib.callback.await('resourcename:checkout', false, data.roomId)
    cb({ success = result })
end)
```

Each callback must call `cb(...)` exactly once. The value passed to `cb` is returned to the JS
`fetch` call as JSON.

## React side

```tsx
const resourceName = (window as any).GetParentResourceName?.() ?? 'resourcename'

async function nuiPost<T>(endpoint: string, payload: unknown): Promise<T> {
    const resp = await fetch(`https://${resourceName}/${endpoint}`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify(payload),
    })
    return resp.json()
}

// receive messages from Lua
useEffect(() => {
    const handler = ({ data }: MessageEvent) => {
        if (data.action === 'open') setVisible(true)
        if (data.action === 'close') setVisible(false)
    }
    window.addEventListener('message', handler)
    return () => window.removeEventListener('message', handler)
}, [])

// send to Lua
const handleClose = async () => {
    await nuiPost('close', {})
    setVisible(false)
}
```

## Dev workflow

```bash
cd web
bun install
bun run dev     # hot reload in browser (mock GetParentResourceName)
bun run build   # outputs to web/dist/
```

## Visibility pattern

Keep the React tree mounted; toggle visibility with CSS or a state flag. Avoids React re-mount
cost every time the UI opens.

```tsx
<div style={{ display: visible ? 'flex' : 'none' }}>
    <App />
</div>
```
