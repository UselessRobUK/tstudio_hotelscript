local Config = require "configs.shared.main"
local Hotels = require "configs.shared.hotels"

local Zones = {
    active        = {},
    currentHotel  = nil,
    currentRoom   = nil,
    pendingAction = nil,
}

local Target    = Config.UseTarget and require "bridge.target" or nil
local useTarget = Target and Target.type ~= "standalone"

local interactKey
if not useTarget then
    interactKey = lib.addKeybind({
        name        = 'hotel_interact',
        description = 'Hotel Interact',
        defaultKey  = 'e',
        disabled    = true,
        onPressed   = function()
            if Zones.pendingAction then Zones.pendingAction() end
        end,
    })
end

local function enterZone(label, action, stateEnter)
    if stateEnter then stateEnter() end
    Zones.pendingAction = action
    lib.showTextUI(label, { position = 'right-center' })
    interactKey:enable()
end

local function exitZone()
    Zones.pendingAction = nil
    lib.hideTextUI()
    interactKey:disable()
end

---@param id      string
---@param coords  vector3
---@param radius  number   sphere radius (non-target path)
---@param size    vector3  box size (target path)
---@param label   string   display text, without [E] prefix
---@param icon    string   Font Awesome 6 icon class
---@param action  fun()
---@param stateEnter? fun()
local function registerZone(id, coords, radius, size, label, icon, action, stateEnter)
    if useTarget then
        Target.AddBoxZone(id, coords, size, {
            distance = radius,
            options  = {
                {
                    label    = label,
                    icon     = icon,
                    onSelect = function()
                        if stateEnter then stateEnter() end
                        action()
                    end,
                },
            },
        })
        return
    end

    lib.zones.sphere({
        coords  = coords,
        radius  = radius,
        debug   = Config.Debug,
        onEnter = function()
            enterZone(("[E] %s"):format(label), action, stateEnter)
        end,
        onExit  = exitZone,
    })
end

for _, hotel in pairs(Hotels) do
    if hotel.entrance then
        registerZone(
            "hotel_entrance_" .. hotel.id,
            vec3(hotel.entrance.x, hotel.entrance.y, hotel.entrance.z),
            2.0, vec3(1.5, 1.5, 2.0),
            "Open Hotel", "fas fa-hotel",
            function() TriggerEvent("hotel:openMenu", hotel.id) end,
            function() Zones.currentHotel = hotel.id end
        )
    end

    if hotel.boss then
        registerZone(
            "hotel_boss_" .. hotel.id,
            vec3(hotel.boss.x, hotel.boss.y, hotel.boss.z),
            2.0, vec3(1.5, 1.5, 2.0),
            "Hotel Management", "fas fa-user-tie",
            function() TriggerEvent("hotel:openBossMenu", hotel.id) end
        )
    end

    if hotel.rooms then
        for _, room in pairs(hotel.rooms) do
            if room.entrance then
                local point = room.entrance.coords or room.entrance
                registerZone(
                    ("hotel_room_%s_%s"):format(hotel.id, room.id),
                    vec3(point.x, point.y, point.z),
                    2.0, vec3(1.0, 1.0, 2.0),
                    room.label or ("Room " .. room.id), "fas fa-door-open",
                    function() TriggerEvent("hotel:enterRoom", hotel.id, room.id) end,
                    function()
                        Zones.currentHotel = hotel.id
                        Zones.currentRoom  = room.id
                    end
                )
            end

            if room.stash then
                registerZone(
                    ("hotel_stash_%s_%s"):format(hotel.id, room.id),
                    vec3(room.stash.x, room.stash.y, room.stash.z),
                    1.5, vec3(1.0, 1.0, 1.0),
                    "Open Stash", "fas fa-box",
                    function() TriggerEvent("hotel:openStash", hotel.id, room.id) end
                )
            end

            if room.wardrobe then
                registerZone(
                    ("hotel_wardrobe_%s_%s"):format(hotel.id, room.id),
                    vec3(room.wardrobe.x, room.wardrobe.y, room.wardrobe.z),
                    1.5, vec3(1.0, 1.0, 1.0),
                    "Wardrobe", "fas fa-shirt",
                    function() TriggerEvent("hotel:openWardrobe", hotel.id, room.id) end
                )
            end

            if room.exit then
                registerZone(
                    ("hotel_exit_%s_%s"):format(hotel.id, room.id),
                    vec3(room.exit.x, room.exit.y, room.exit.z),
                    1.5, vec3(1.0, 1.0, 1.0),
                    "Exit Room", "fas fa-door-closed",
                    function() TriggerEvent("hotel:exitRoom", hotel.id, room.id) end
                )
            end
        end
    end
end

RegisterNetEvent("hotel:setCurrentZone", function(hotelId, roomId)
    Zones.currentHotel = hotelId
    Zones.currentRoom  = roomId
end)

exports("GetCurrentHotelZone", function()
    return { hotel = Zones.currentHotel, room = Zones.currentRoom }
end)

exports("IsInHotelZone", function()
    return Zones.currentHotel ~= nil
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Zones.active        = {}
    Zones.currentHotel  = nil
    Zones.currentRoom   = nil
    Zones.pendingAction = nil
end)
