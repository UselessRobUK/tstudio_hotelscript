--========================================================--
-- Standalone Hotel Framework
-- server/complaints.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Complaints = Hotel.Complaints or {}

local function Notify(src, msg, t)
    Hotel.Notify(src, msg, t or "inform")
end

RegisterNetEvent("hotel:submitComplaint", function(data)
    local src = source
    if type(data) ~= "table" then return end

    local identifier = Hotel.GetIdentifier(src)
    if not identifier then return end

    local hotelId = data.hotel
    local message = tostring(data.message or "")
    local category = tostring(data.category or "Other")

    if message == "" then
        return Notify(src, "Complaint message required.", "error")
    end

    Hotel.Complaints[hotelId] = Hotel.Complaints[hotelId] or {}

    local complaint = {
        id = #Hotel.Complaints[hotelId] + 1,
        hotel = hotelId,
        identifier = identifier,
        room = tonumber(data.roomId),
        category = category,
        message = message,
        status = "open",
        created_at = os.time()
    }

    Hotel.Complaints[hotelId][#Hotel.Complaints[hotelId] + 1] = complaint

    if MySQL then
        local id = MySQL.insert.await([[
            INSERT INTO hotel_complaints
            (hotel, identifier, room, category, message, status, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], {
            hotelId,
            identifier,
            complaint.room,
            category,
            message,
            complaint.status,
            complaint.created_at
        })

        complaint.id = id or complaint.id
    end

    TriggerClientEvent("hotel:complaintSubmitted", src)
    Notify(src, "Complaint submitted.", "success")
end)

RegisterNetEvent("hotel:getComplaints", function(hotelId)
    local src = source

    if Hotel.IsBoss and not Hotel.IsBoss(src, hotelId) then
        return Notify(src, "No permission.", "error")
    end

    TriggerClientEvent(
        "hotel:receiveComplaints",
        src,
        hotelId,
        Hotel.Complaints[hotelId] or {}
    )
end)

RegisterNetEvent("hotel:resolveComplaint", function(hotelId, complaintId)
    local src = source

    if Hotel.IsBoss and not Hotel.IsBoss(src, hotelId) then
        return Notify(src, "No permission.", "error")
    end

    complaintId = tonumber(complaintId)
    local list = Hotel.Complaints[hotelId] or {}

    for _, complaint in pairs(list) do
        if tonumber(complaint.id) == complaintId then
            complaint.status = "resolved"
            complaint.resolved_at = os.time()
            complaint.resolved_by = Hotel.GetIdentifier(src)

            if MySQL then
                MySQL.update.await([[
                    UPDATE hotel_complaints
                    SET status = ?, resolved_at = ?, resolved_by = ?
                    WHERE id = ?
                ]], {
                    "resolved",
                    complaint.resolved_at,
                    complaint.resolved_by,
                    complaint.id
                })
            end

            Notify(src, "Complaint resolved.", "success")
            return
        end
    end

    Notify(src, "Complaint not found.", "error")
end)

CreateThread(function()
    Wait(2500)

    if not MySQL then return end

    local rows = MySQL.query.await(
        "SELECT * FROM hotel_complaints WHERE status != ?",
        { "resolved" }
    )

    for _, row in pairs(rows or {}) do
        Hotel.Complaints[row.hotel] = Hotel.Complaints[row.hotel] or {}
        Hotel.Complaints[row.hotel][#Hotel.Complaints[row.hotel] + 1] = row
    end
end)

exports("GetHotelComplaints", function(hotelId)
    return Hotel.Complaints[hotelId] or {}
end)
