local State = require "server.state"

local function Main() return require "server.main" end

---@param hotelId string
---@param roomId number
---@param state string
local function SetRoomState(hotelId, roomId, state)
    State.RoomStates[hotelId .. "_" .. tonumber(roomId)] = state
    MySQL.insert.await(
        "INSERT INTO hotel_room_states (hotel, room, state, updated_at) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE state = VALUES(state), updated_at = VALUES(updated_at)",
        { hotelId, tonumber(roomId), state, os.time() }
    )
end

---@param hotelId string
---@param roomId number
local function SetDirty(hotelId, roomId)
    SetRoomState(hotelId, roomId, "dirty")
end

---@param hotelId string
---@param roomId number
local function SetClean(hotelId, roomId)
    SetRoomState(hotelId, roomId, "clean")
end

---@param hotelId string
---@param roomId number
---@return string
local function GetState(hotelId, roomId)
    return State.RoomStates[hotelId .. "_" .. tonumber(roomId)] or "clean"
end

RegisterNetEvent("hotel:requestCleaning", function(hotelId, roomId)
    local src  = source
    local room = Main().GetRoom(hotelId, tonumber(roomId))
    if not room then return Main().Notify(src, "Invalid room.", "error") end
    if GetState(hotelId, roomId) ~= "dirty" then
        return TriggerClientEvent("hotel:cleaningFailed", src, "Room is already clean.")
    end
    TriggerClientEvent("hotel:startCleaning", src, hotelId, tonumber(roomId))
end)

RegisterNetEvent("hotel:finishCleaning", function(hotelId, roomId)
    local src  = source
    local room = Main().GetRoom(hotelId, tonumber(roomId))
    if not room then return end
    SetClean(hotelId, tonumber(roomId))
    Main().Notify(src, "Room marked as clean.", "success")
end)

CreateThread(function()
    Wait(2500)
    local rows = MySQL.query.await("SELECT * FROM hotel_room_states", {})
    for _, row in pairs(rows or {}) do
        State.RoomStates[row.hotel .. "_" .. tonumber(row.room)] = row.state
    end
end)

exports("SetHotelRoomDirty", SetDirty)
exports("SetHotelRoomClean", SetClean)
exports("GetHotelRoomState", GetState)

return { SetDirty = SetDirty, SetClean = SetClean, GetState = GetState }
