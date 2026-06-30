# Classes - lib.class

ox_lib provides a class system via `lib.class`. Prefer it over raw metatables for anything
with more than one or two methods.

Docs: https://overextended.dev/docs/ox_lib/Class

---

## Defining a class

```lua
---@class RoomManager
---@field id     number
---@field rate   number
---@field owner  number?
local RoomManager = lib.class('RoomManager')

---@param id   number
---@param rate number
function RoomManager:constructor(id, rate)
    self.id    = id
    self.rate  = rate
    self.owner = nil
end

---@param source number
---@return boolean
function RoomManager:checkin(source)
    if self.owner then return false end
    self.owner   = source
    self.checkin = os.time()
    Player(source).state.roomId = self.id
    return true
end

---@return boolean
function RoomManager:checkout()
    if not self.owner then return false end
    Player(self.owner).state.roomId = nil
    self.owner   = nil
    self.checkin = nil
    return true
end

---@return boolean
function RoomManager:isOccupied()
    return self.owner ~= nil
end

---@param source number
---@return boolean
function RoomManager:isOwnedBy(source)
    return self.owner == source
end
```

---

## Instantiation

```lua
---@type table<number, RoomManager>
local rooms = {}

local Config = require "configs.shared.main"

for _, roomData in ipairs(Config.rooms) do
    rooms[roomData.id] = RoomManager:new(roomData.id, roomData.rate)
end
```

---

## Inheritance

```lua
---@class SuiteRoom : RoomManager
---@field maxGuests number
local SuiteRoom = lib.class('SuiteRoom', RoomManager)

---@param id        number
---@param rate      number
---@param maxGuests number
function SuiteRoom:constructor(id, rate, maxGuests)
    self:super(id, rate)
    self.maxGuests = maxGuests
    self.guests    = {}
end

---@param source number
---@return boolean
function SuiteRoom:addGuest(source)
    if #self.guests >= self.maxGuests then return false end
    self.guests[#self.guests + 1] = source
    return true
end

---@param source number
function SuiteRoom:removeGuest(source)
    for i, guest in ipairs(self.guests) do
        if guest == source then
            table.remove(self.guests, i)
            return
        end
    end
end
```

---

## Type checking

```lua
local room = rooms[roomId]

if room:isa(SuiteRoom) then
    room:addGuest(source)
end

if room:isa(RoomManager) then   -- true for SuiteRoom too (inherited)
    room:checkin(source)
end
```

---

## Practical patterns

### Per-player session class

```lua
---@class PlayerSession
---@field source number
---@field job    string
---@field joined number
local PlayerSession = lib.class('PlayerSession')

function PlayerSession:constructor(source, job)
    self.source = source
    self.job    = job
    self.joined = os.time()
end

---@return number  seconds since joined
function PlayerSession:sessionAge()
    return os.time() - self.joined
end

---@param newJob string
function PlayerSession:setJob(newJob)
    self.job                    = newJob
    Player(self.source).state.job = newJob
end

---@type table<number, PlayerSession>
local sessions = {}

AddEventHandler('playerDropped', function()
    sessions[source] = nil
end)
```

### Using in a callback

```lua
lib.callback.register('resourcename:checkin', function(source, roomId)
    if not isPlayerLoaded(source) then return false end

    local room    = rooms[roomId]
    local session = sessions[source]

    if not room or not session then return false end
    if not Bridge.removeMoney(source, room.rate) then return false end

    return room:checkin(source)
end)
```

---

## Notes

- `self:super(...)` calls the parent constructor; call it first in child constructors.
- `lib.class` handles `__index` chaining so inherited methods resolve automatically.
- Annotate the class with `---@class Name` and fields with `---@field` for full IDE support.
- For `---@class Child : Parent` LuaDoc inheritance, the parent must be annotated first.
