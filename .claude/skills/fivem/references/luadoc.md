# LuaDoc / LuaTypes Conventions

Annotate every non-trivial function and every shared type. Nothing else gets comments.

## Functions

```lua
---@param source  number
---@param roomId  number
---@return boolean
local function playerOwnsRoom(source, roomId)
    local room = occupiedRooms[roomId]
    return room ~= nil and room.owner == source
end
```

Multiple return values:

```lua
---@param source number
---@return boolean, string?
local function validateCheckin(source)
    if not isPlayerLoaded(source) then return false, 'not_loaded' end
    return true, nil
end
```

---

## Classes

```lua
---@class RoomRecord
---@field id       number
---@field owner    number
---@field checkin  number   unix timestamp
---@field rate     number
---@field locked   boolean

---@type table<number, RoomRecord>
local occupiedRooms = {}
```

Optional fields:

```lua
---@class CheckinOptions
---@field duration  number?
---@field discount  number?
```

---

## Aliases

```lua
---@alias JobName 'police' | 'ambulance' | 'mechanic'

---@param source number
---@return JobName | nil
local function getPlayerJob(source)
    return Player(source).state.job
end
```

---

## Typed tables and generics

```lua
---@type table<number, boolean>
local activeSessions = {}

---@type string[]
local allowedItems = { 'keycard', 'masterkey' }
```

---

## Varargs

```lua
---@param ... any
local function debugPrint(...)
    print(...)
end
```
