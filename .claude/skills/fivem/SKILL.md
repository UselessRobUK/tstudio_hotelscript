---
name: fivem
description: >
  FiveM resource development with Lua and ox_lib. Use whenever the user is writing, debugging, or
  reviewing FiveM/CitizenFX scripts - including server/client Lua, NUI (Vite/React), ox_lib
  callbacks, commands, context menus, progress bars, oxmysql queries, ox_target zones, bridge
  patterns, or fxmanifest setup. Apply when the user mentions FiveM, CFX, ox_lib, oxmysql,
  ox_target, ox_inventory, fxmanifest, RegisterNetEvent, TriggerServerEvent, NUI, statebags,
  or Lua in a GTA V / CitizenFX context. Also trigger when the user asks about resource
  structure, server-authority patterns, or any ox ecosystem resource.
---

# FiveM Resource Development

## Non-negotiable principles

- **Server authority**: the server owns all mutable state. Clients request; the server validates
  and executes. Never award items, money, or modify persistent state based solely on a client event.
- **No global pollution**: every value is local to its module. Configs loaded via `require`, never
  assigned to globals.
- **ox_lib first**: prefer ox_lib APIs over raw natives wherever an equivalent exists.
- **Self-documenting names**: no inline narrative comments, no section dividers. Only LuaDoc /
  LuaTypes annotations.
- **oxmysql only**: SQL auto-injected on resource start. No other MySQL resource.
- **Bridge everything external**: inventory, banking, doorlocks go through `bridge/` so providers
  are swappable without touching feature code.

## External docs

- Natives: https://docs.fivem.net/natives/
- Scripting reference: https://docs.fivem.net/docs/scripting-reference/
- ox ecosystem: https://overextended.dev/docs

## Reference files

Load only what the task needs.

| File | Load when |
|------|-----------|
| `references/structure.md`    | setting up a resource, fxmanifest, file layout, `_index.lua`, `require` |
| `references/luadoc.md`       | writing any typed Lua - `@param`, `@return`, `@class`, `@alias`         |
| `references/callbacks.md`    | client↔server communication, `lib.callback`, commands, net events        |
| `references/interface.md`    | any client-side UI - notify, progress, menus, zones, ox_target           |
| `references/nui.md`          | building a Vite+React NUI                                                 |
| `references/state.md`        | statebags, ephemeral state, threads, native caching                       |
| `references/bridge.md`       | writing or consuming a bridge module                                      |
| `references/classes.md`      | `lib.class` - defining classes, inheritance, per-player session pattern   |
| `references/ox-ecosystem.md` | oxmysql queries, ox_inventory exports, ox_lib module list                 |
| `references/natives.md`      | common native patterns, namespaces, vectors, hashes, events               |
| `references/security.md`     | reviewing or writing any server-side handler                              |
| `references/logging.md`      | `debugPrint`, `lib.logger`, locale init                                   |
| `references/advanced/http-handler.md`    | reusable `SetHttpHandler` router + token auth module      |
| `references/advanced/nui-server-direct.md` | NUI → server directly, skipping the client relay       |
