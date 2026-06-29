local Config = require "configs.shared.main"

local type = "standalone"

if GetResourceState("ox_target") == "started" then
    type = "ox"
elseif GetResourceState("qb-target") == "started" then
    type = "qb"
elseif GetResourceState("interact") == "started" then
    type = "interact"
end

---@param id string
---@param coords vector3
---@param size vector3
---@param options table
local function AddBoxZone(id, coords, size, options)
    size    = size or vec3(1.0, 1.0, 2.0)
    options = options or {}

    if type == "ox" then
        exports.ox_target:addBoxZone({
            name     = id,
            coords   = coords,
            size     = size,
            rotation = options.rotation or 0.0,
            debug    = Config.Debug,
            options  = options.options or {},
        })
        return
    end

    if type == "qb" then
        exports["qb-target"]:AddBoxZone(id, coords, size.x, size.y, {
            heading  = options.rotation or 0,
            debugPoly = Config.Debug,
            minZ     = coords.z - 1,
            maxZ     = coords.z + 2,
        }, {
            options  = options.options or {},
            distance = options.distance or 2.0,
        })
        return
    end

    if type == "interact" then
        exports.interact:AddInteraction({
            coords      = coords,
            distance    = options.distance or 2.0,
            interactDst = options.distance or 2.0,
            id          = id,
            options     = options.options or {},
        })
    end
end

---@param id string
local function Remove(id)
    if type == "ox" then
        exports.ox_target:removeZone(id)
    elseif type == "qb" then
        exports["qb-target"]:RemoveZone(id)
    elseif type == "interact" then
        exports.interact:RemoveInteraction(id)
    end
end

---@param hotel table
local function RegisterReception(hotel)
    if not hotel.reception then return end

    AddBoxZone("hotel_reception_" .. hotel.id, vec3(
        hotel.reception.coords.x,
        hotel.reception.coords.y,
        hotel.reception.coords.z
    ), vec3(1.5, 1.5, 2.0), {
        distance = 2.0,
        options  = {
            {
                label    = "Open Reception",
                icon     = "fas fa-hotel",
                onSelect = function()
                    TriggerEvent("hotel:openReception", hotel.id)
                end,
            },
        },
    })
end

---@param hotelId string
---@param room table
local function RegisterRoom(hotelId, room)
    if not room.entrance then return end
    local pos = room.entrance.coords or room.entrance

    AddBoxZone(("hotel_room_%s_%s"):format(hotelId, room.id), vec3(pos.x, pos.y, pos.z),
        vec3(1.0, 1.0, 2.0), {
        distance = 1.5,
        options  = {
            {
                label    = "Enter Room",
                icon     = "fas fa-door-open",
                onSelect = function()
                    TriggerEvent("hotel:enterRoom", hotelId, room.id)
                end,
            },
        },
    })
end

return {
    type              = type,
    AddBoxZone        = AddBoxZone,
    Remove            = Remove,
    RegisterReception = RegisterReception,
    RegisterRoom      = RegisterRoom,
}
