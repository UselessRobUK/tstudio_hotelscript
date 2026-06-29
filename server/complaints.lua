local State = require "server.state"

local function Main() return require "server.main" end
local function Boss() return require "server.boss" end

RegisterNetEvent("hotel:submitComplaint", function(data)
    local src = source
    if type(data) ~= "table" then return end

    local identifier = Main().GetIdentifier(src)
    if not identifier then return end

    local hotelId  = data.hotel
    local message  = tostring(data.message or "")
    local category = tostring(data.category or "Other")

    if message == "" then return Main().Notify(src, "Complaint message required.", "error") end

    State.Complaints[hotelId] = State.Complaints[hotelId] or {}

    local complaint = {
        id         = #State.Complaints[hotelId] + 1,
        hotel      = hotelId,
        identifier = identifier,
        room       = tonumber(data.roomId),
        category   = category,
        message    = message,
        status     = "open",
        created_at = os.time(),
    }

    State.Complaints[hotelId][#State.Complaints[hotelId] + 1] = complaint

    local id = MySQL.insert.await(
        "INSERT INTO hotel_complaints (hotel, identifier, room, category, message, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
        { hotelId, identifier, complaint.room, category, message, complaint.status, complaint.created_at }
    )
    complaint.id = id or complaint.id

    TriggerClientEvent("hotel:complaintSubmitted", src)
    Main().Notify(src, "Complaint submitted.", "success")
end)

lib.callback.register("hotel:getComplaints", function(src, hotelId)
    if not Boss().IsBoss(src, hotelId) then return nil end
    return State.Complaints[hotelId] or {}
end)

RegisterNetEvent("hotel:resolveComplaint", function(hotelId, complaintId)
    local src = source
    if not Boss().IsBoss(src, hotelId) then return Main().Notify(src, "No permission.", "error") end

    complaintId = tonumber(complaintId)
    for _, complaint in pairs(State.Complaints[hotelId] or {}) do
        if tonumber(complaint.id) == complaintId then
            complaint.status      = "resolved"
            complaint.resolved_at = os.time()
            complaint.resolved_by = Main().GetIdentifier(src)
            MySQL.update.await(
                "UPDATE hotel_complaints SET status = ?, resolved_at = ?, resolved_by = ? WHERE id = ?",
                { "resolved", complaint.resolved_at, complaint.resolved_by, complaint.id }
            )
            Main().Notify(src, "Complaint resolved.", "success")
            return
        end
    end
    Main().Notify(src, "Complaint not found.", "error")
end)

CreateThread(function()
    Wait(2500)
    local rows = MySQL.query.await("SELECT * FROM hotel_complaints WHERE status != ?", { "resolved" })
    for _, row in pairs(rows or {}) do
        State.Complaints[row.hotel] = State.Complaints[row.hotel] or {}
        State.Complaints[row.hotel][#State.Complaints[row.hotel] + 1] = row
    end
end)

exports("GetHotelComplaints", function(hotelId)
    return State.Complaints[hotelId] or {}
end)
