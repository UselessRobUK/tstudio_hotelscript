# Client Interface

All client-side. ox_lib UI + zones + ox_target.

## Notify

```lua
lib.notify({
    title       = 'Label',
    description = 'Optional detail',
    type        = 'success',  -- 'success' | 'error' | 'warning' | 'info'
    duration    = 3000,       -- ms, optional
    icon        = 'check',    -- Font Awesome 6 icon, optional
})
```

---

## Text UI

```lua
lib.showTextUI('[E] Interact', {
    position = 'right-center',  -- 'right-center' | 'left-center' | 'top-center' | 'bottom-center'
    icon     = 'hand',
})
lib.hideTextUI()
```

---

## Progress bar

```lua
local completed = lib.progressBar({
    duration     = 3000,
    label        = 'Working...',
    useWhileDead = false,
    canCancel    = true,
    disable      = { move = true, car = true, combat = true },
    anim         = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' },
})
if not completed then return end
```

---

## Skill check

```lua
local passed = lib.skillCheck(
    { 'easy', 'easy', { areaSize = 60, speedMultiplier = 2 }, 'hard' },
    { 'w', 'a', 's', 'd' }
)
if not passed then return end
```

Difficulty presets: `'easy'` | `'medium'` | `'hard'`
Custom: `{ areaSize = 1-100, speedMultiplier = number }`

---

## Input dialog

```lua
local input = lib.inputDialog('Dialog Title', {
    { type = 'input',    label = 'Name',     required = true                   },
    { type = 'number',   label = 'Amount',   required = true, min = 1, max = 99 },
    { type = 'checkbox', label = 'Confirm'                                     },
    { type = 'select',   label = 'Type', options = {
        { value = 'a', label = 'Option A' },
        { value = 'b', label = 'Option B' },
    }},
})
if not input then return end
local name, amount, confirmed, type = input[1], input[2], input[3], input[4]
```

---

## Context menu

```lua
lib.registerContext({
    id       = 'resourcename_main',
    title    = 'Menu Title',
    options  = {
        {
            title       = 'Option label',
            description = 'Detail text',
            icon        = 'door-open',
            disabled    = false,
            onSelect    = function()
                local ok = lib.callback.await('resourcename:doThing', false)
                lib.notify({ title = ok and 'Done' or 'Failed', type = ok and 'success' or 'error' })
            end,
        },
        {
            title   = 'Open submenu',
            arrow   = true,
            onSelect = function()
                lib.showContext('resourcename_sub')
            end,
        },
    },
})
lib.showContext('resourcename_main')
lib.hideContext()      -- programmatic close
lib.getOpenContextMenu()  -- returns id of open menu or nil
```

---

## Zones (lib.zones)

```lua
local sphere = lib.zones.sphere({
    coords   = vector3(100.0, 200.0, 30.0),
    radius   = 5.0,
    debug    = Config.debug,   -- draws zone outline; tie to your debug config flag
    onEnter  = function() lib.showTextUI('[E] Interact') end,
    onExit   = function() lib.hideTextUI() end,
})

local box = lib.zones.box({
    coords   = vector3(100.0, 200.0, 30.0),
    size     = vector3(4.0, 4.0, 3.0),
    rotation = 45.0,
    debug    = Config.debug,
    onEnter  = function() end,
    onExit   = function() end,
})

local poly = lib.zones.poly({
    points    = { vector3(x1,y1,z1), vector3(x2,y2,z2), vector3(x3,y3,z3) },
    thickness = 2.0,
    debug     = Config.debug,
    onEnter   = function() end,
    onExit    = function() end,
})

sphere:remove()
```

---

## lib.points

More performant than zones when checking many world positions - uses a grid-based system
instead of per-frame distance checks against every point. Prefer it over zones when the
trigger is proximity-based UI or per-frame nearby logic.

```lua
local point = lib.points.new({
    coords   = vector3(100.0, 200.0, 30.0),
    distance = 10.0,

    onEnter = function(self)
        lib.showTextUI('[E] Interact')
    end,

    onExit = function(self)
        lib.hideTextUI()
    end,

    nearby = function(self, distance)
        -- called every frame while player is within self.distance
        if distance < 2.0 and IsControlJustReleased(0, 38) then
            lib.callback.await('resourcename:interact', false)
        end
    end,
})

point:remove()
```

Use `lib.zones` when you need a shaped boundary (box, poly). Use `lib.points` when you just
need a radius and per-frame nearby logic.

---

## ox_target

```lua
-- entity target (e.g. an NPC or prop)
exports.ox_target:addLocalEntity(entity, {
    {
        name     = 'resourcename:interact',
        icon     = 'fas fa-door-open',
        label    = 'Enter room',
        distance = 2.0,
        onSelect = function()
            lib.callback.await('resourcename:enterRoom', false)
        end,
    },
})
exports.ox_target:removeLocalEntity(entity, { 'resourcename:interact' })

-- box zone
exports.ox_target:addBoxZone({
    coords   = vector3(100.0, 200.0, 30.0),
    size     = vector3(2.0, 2.0, 2.0),
    rotation = 0.0,
    options  = {
        {
            name     = 'resourcename:desk',
            icon     = 'fas fa-concierge-bell',
            label    = 'Check in',
            onSelect = function() lib.showContext('resourcename_checkin') end,
        },
    },
})

-- global model
exports.ox_target:addModel(`s_m_y_cop`, {
    { name = 'resourcename:cop', label = 'Talk', icon = 'fas fa-comment', onSelect = function() end },
})
```

Option shape:

```lua
{
    name        = 'uniqueId',        -- required; used for removal
    label       = 'Display label',
    icon        = 'fas fa-hand',     -- Font Awesome 6
    distance    = 2.0,
    canInteract = function(entity, distance, coords, name, bone)
        return true
    end,
    onSelect    = function(data)     -- data.entity, data.coords, data.zone, data.name
    end,
}
```
