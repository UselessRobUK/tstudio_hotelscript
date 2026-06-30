local Config = require "configs.shared.main"
local Hotels = require "configs.shared.hotels"
local Rooms  = require "configs.shared.rooms"
local Notify = require "client.notifications"

---@return boolean hit, vector3 coords, number|nil entity
local function RaycastCam()
    local camCoords = GetGameplayCamCoords()
    local camRot    = GetGameplayCamRot(2)
    local r         = math.rad
    local x = -math.sin(r(camRot.z)) * math.cos(r(camRot.x))
    local y =  math.cos(r(camRot.z)) * math.cos(r(camRot.x))
    local z =  math.sin(r(camRot.x))
    local dest = camCoords + vector3(x, y, z) * 15.0
    local _, hit, coords, _, entity = GetShapeTestResult(
        StartExpensiveSynchronousShapeTestLosProbe(
            camCoords.x, camCoords.y, camCoords.z,
            dest.x, dest.y, dest.z,
            -1, PlayerPedId(), 4
        )
    )
    return hit == 1, coords, entity ~= 0 and entity or nil
end

-- Blocking placement mode.
-- Returns {coords, entity} if placed, false if skipped, nil if cancelled (ESC).
---@param label   string
---@param optional? boolean  allow [BACKSPACE] to skip
---@return {coords: vector3, entity: number|nil}|false|nil
local function PlaceMode(label, optional)
    local placed  = nil
    local running = true

    lib.showTextUI(
        optional
            and ("[E] Set %s  [BACKSPACE] Skip  [ESC] Cancel"):format(label)
            or  ("[E] Set %s  [ESC] Cancel"):format(label),
        { position = "top-center" }
    )

    CreateThread(function()
        while running do
            Wait(0)
            local hit, coords, entity = RaycastCam()
            if hit then
                DrawMarker(28,
                    coords.x, coords.y, coords.z,
                    0,0,0, 0,0,0, 0.3,0.3,0.3,
                    255, 200, 0, 200,
                    false, true, 2, nil, nil, false)
            end

            if IsControlJustPressed(0, 38) then         -- [E] place
                if hit then
                    placed  = { coords = coords, entity = entity }
                    running = false
                end
            elseif optional and IsControlJustPressed(0, 194) then  -- [BACKSPACE] skip
                placed  = false
                running = false
            elseif IsControlJustPressed(0, 200) then    -- [ESC] cancel
                running = false
            end
        end
    end)

    while running do Wait(50) end
    lib.hideTextUI()
    return placed
end

---@param hotelId  string
---@param existing? table  pre-fill for editing
local function BuildRoom(hotelId, existing)
    local inputs = lib.inputDialog(
        existing and ("Edit Room — " .. hotelId) or ("New Room — " .. hotelId),
        {
            { type = "number", label = "Room ID",         default = existing and existing.id       or 101, required = true, min = 1    },
            { type = "input",  label = "Label",           default = existing and existing.label    or "",  required = true             },
            { type = "number", label = "Price",           default = existing and existing.price    or 250, required = true, min = 0    },
            { type = "number", label = "Duration (hrs)",  default = existing and existing.duration or 24,  required = true, min = 1    },
        }
    )
    if not inputs then return end

    local roomId   = math.floor(tonumber(inputs[1]) or 101)
    local label    = inputs[2]
    local price    = math.floor(tonumber(inputs[3]) or 250)
    local duration = math.floor(tonumber(inputs[4]) or 24)

    -- Door (required for doorlock)
    Notify.Info("Look at the door entity and press [E].")
    local doorResult = PlaceMode("Door")
    if doorResult == nil then return Notify.Info("Cancelled.") end

    local door = existing and existing.door or nil
    if doorResult then
        local c       = doorResult.coords
        local entity  = doorResult.entity
        door = {
            id      = ("%s_%s"):format(hotelId, roomId),
            coords  = { x = c.x, y = c.y, z = c.z },
            heading = entity and GetEntityHeading(entity) or 0.0,
            model   = entity and GetEntityModel(entity) or nil,
        }
    end

    -- Stash (optional)
    Notify.Info("Look at the stash spot. [BACKSPACE] to skip.")
    local stashResult = PlaceMode("Stash", true)
    if stashResult == nil then return Notify.Info("Cancelled.") end
    local stash = existing and existing.stash or nil
    if stashResult then
        local c = stashResult.coords
        stash = { x = c.x, y = c.y, z = c.z }
    end

    -- Wardrobe (optional)
    Notify.Info("Look at the wardrobe spot. [BACKSPACE] to skip.")
    local wardrobeResult = PlaceMode("Wardrobe", true)
    if wardrobeResult == nil then return Notify.Info("Cancelled.") end
    local wardrobe = existing and existing.wardrobe or nil
    if wardrobeResult then
        local c = wardrobeResult.coords
        wardrobe = { x = c.x, y = c.y, z = c.z }
    end

    local room = {
        id       = roomId,
        label    = label,
        price    = price,
        duration = duration,
        door     = door,
        stash    = stash,
        wardrobe = wardrobe,
    }

    local ok = lib.callback.await("hotel:saveCreatorRoom", false, hotelId, room)
    if ok then
        Notify.Success(("Room %s saved to rooms.lua"):format(roomId))
    else
        Notify.Error("Save failed — check server console.")
    end
end

local function OpenHotelMenu(hotel)
    local existing = Rooms[hotel.id] or {}
    local options  = {
        {
            title    = "+ Add New Room",
            icon     = "plus",
            onSelect = function()
                CreateThread(function() BuildRoom(hotel.id) end)
            end,
        },
    }
    for _, room in ipairs(existing) do
        local r = room
        options[#options + 1] = {
            title       = r.label or ("Room " .. r.id),
            description = ("Price: %s  |  %sh"):format(r.price, r.duration),
            onSelect    = function()
                CreateThread(function() BuildRoom(hotel.id, r) end)
            end,
        }
    end
    lib.registerContext({
        id      = "creator_hotel_" .. hotel.id,
        title   = hotel.name or hotel.id,
        options = options,
    })
    lib.showContext("creator_hotel_" .. hotel.id)
end

RegisterCommand("hotelcreator", function()
    local hotelOptions = {}
    for _, hotel in pairs(Hotels) do
        local h = hotel
        hotelOptions[#hotelOptions + 1] = {
            title       = hotel.name or hotel.id,
            description = "id: " .. hotel.id,
            onSelect    = function() OpenHotelMenu(h) end,
        }
    end
    lib.registerContext({
        id      = "creator_main",
        title   = "Hotel Room Creator",
        options = hotelOptions,
    })
    lib.showContext("creator_main")
end, false)
