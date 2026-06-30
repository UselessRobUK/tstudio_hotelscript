local function Security() return require "server.security" end
local DoorLock = require "bridge.doorlock"

local function fmtNum(n)
    if n == math.floor(n) then return tostring(math.floor(n)) end
    return ("%.4f"):format(n)
end

local function fmtVec3(v)
    return ("vector3(%s, %s, %s)"):format(fmtNum(v.x), fmtNum(v.y), fmtNum(v.z))
end

local function WriteRooms(allRooms)
    local lines = { "return {" }

    for hotelId, rooms in pairs(allRooms) do
        lines[#lines + 1] = ("    %s = {"):format(hotelId)
        for _, r in ipairs(rooms) do
            lines[#lines + 1] = "        {"
            lines[#lines + 1] = ("            id       = %s,"):format(fmtNum(r.id))
            lines[#lines + 1] = ("            label    = %q,"):format(r.label)
            lines[#lines + 1] = ("            price    = %s,"):format(fmtNum(r.price))
            lines[#lines + 1] = ("            duration = %s,"):format(fmtNum(r.duration))

            if r.door then
                local d = r.door
                lines[#lines + 1] = ""
                lines[#lines + 1] = "            door = {"
                lines[#lines + 1] = ("                id      = %q,"):format(d.id)
                lines[#lines + 1] = ("                coords  = %s,"):format(fmtVec3(d.coords))
                lines[#lines + 1] = ("                heading = %s,"):format(fmtNum(d.heading))
                if d.model then
                    lines[#lines + 1] = ("                model   = %s,"):format(fmtNum(d.model))
                end
                lines[#lines + 1] = "            },"
            end

            if r.stash then
                lines[#lines + 1] = ("            stash    = %s,"):format(fmtVec3(r.stash))
            end
            if r.wardrobe then
                lines[#lines + 1] = ("            wardrobe = %s,"):format(fmtVec3(r.wardrobe))
            end

            lines[#lines + 1] = "        },"
        end
        lines[#lines + 1] = "    },"
    end

    lines[#lines + 1] = "}"
    return table.concat(lines, "\n")
end

local function LoadRooms()
    local raw = LoadResourceFile(GetCurrentResourceName(), "configs/shared/rooms.lua")
    if not raw or raw == "" then return {} end
    local fn, err = load(raw)
    if not fn then
        print(("^1[HOTEL CREATOR]^7 rooms.lua parse error: %s"):format(err))
        return {}
    end
    local ok, data = pcall(fn)
    if not ok or type(data) ~= "table" then return {} end
    return data
end

lib.callback.register("hotel:saveCreatorRoom", function(src, hotelId, room)
    if not Security().IsAdmin(src) then return false end
    if type(hotelId) ~= "string" or hotelId == "" then return false end
    if type(room) ~= "table" or not room.id then return false end

    local allRooms = LoadRooms()
    if not allRooms[hotelId] then allRooms[hotelId] = {} end

    local replaced = false
    for i, existing in ipairs(allRooms[hotelId]) do
        if tostring(existing.id) == tostring(room.id) then
            allRooms[hotelId][i] = room
            replaced = true
            break
        end
    end
    if not replaced then
        allRooms[hotelId][#allRooms[hotelId] + 1] = room
    end

    local content = WriteRooms(allRooms)
    local ok = SaveResourceFile(GetCurrentResourceName(), "configs/shared/rooms.lua", content, -1)

    if ok then
        DoorLock.Register(room)
        print(("^2[HOTEL CREATOR]^7 Room %s saved for '%s' by %s"):format(
            room.id, hotelId, GetPlayerName(src) or tostring(src)
        ))
    else
        print("^1[HOTEL CREATOR]^7 SaveResourceFile failed for rooms.lua")
    end

    return ok
end)
