--========================================================--
-- Standalone Hotel Framework
-- server/cleaning.lua
--========================================================--

Hotel = Hotel or {}
Hotel.RoomStates = Hotel.RoomStates or {}

local function Notify(src, msg, t)
    Hotel.Notify(src, msg, t or "inform")
end

local function SetRoomState(hotelId, roomId, state)
    Hotel.RoomStates[hotelId] = Hotel.RoomStates[hotelId] or {}
    Hotel.RoomStates[hotelId][tonumber(roomId)] = state

    if MySQL then
        MySQL.insert.await([[
            INSERT INTO hotel_room_states (hotel, room, state, updated_at)
            VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE state = VALUES(state), updated_at = VALUES(updated_at)
        ]], {
            hotelId,
            tonumber(roomId),
            state,
            os.time()
        })
    end
end

function Hotel.SetRoomDirty(hotelId, roomId)
    SetRoomState(hotelId, roomId, "dirty")
end

function Hotel.SetRoomClean(hotelId, roomId)
    SetRoomState(hotelId, roomId, "clean")
end

function Hotel.GetRoomState(hotelId, roomId)
    return Hotel.RoomStates[hotelId]
        and Hotel.RoomStates[hotelId][tonumber(roomId)]
        or "clean"
end

RegisterNetEvent("hotel:requestCleaning", function(hotelId, roomId)
    local src = source

    local room = Hotel.GetRoom(hotelId, tonumber(roomId))
    if not room then
        return Notify(src, "Invalid room.", "error")
    end

    if Hotel.GetRoomState(hotelId, roomId) ~= "dirty" then
        return TriggerClientEvent("hotel:cleaningFailed", src, "Room is already clean.")
    end

    TriggerClientEvent("hotel:startCleaning", src, hotelId, tonumber(roomId))
end)

RegisterNetEvent("hotel:finishCleaning", function(hotelId, roomId)
    local src = source

    local room = Hotel.GetRoom(hotelId, tonumber(roomId))
    if not room then return end

    Hotel.SetRoomClean(hotelId, tonumber(roomId))

    Notify(src, "Room marked as clean.", "success")
end)

CreateThread(function()
    Wait(2500)

    if not MySQL then return end

    local rows = MySQL.query.await("SELECT * FROM hotel_room_states", {})

    for _, row in pairs(rows or {}) do
        Hotel.RoomStates[row.hotel] = Hotel.RoomStates[row.hotel] or {}
        Hotel.RoomStates[row.hotel][tonumber(row.room)] = row.state
    end
end)

exports("SetHotelRoomDirty", Hotel.SetRoomDirty)
exports("SetHotelRoomClean", Hotel.SetRoomClean)
exports("GetHotelRoomState", Hotel.GetRoomState)
