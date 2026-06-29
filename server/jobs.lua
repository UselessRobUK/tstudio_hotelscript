--========================================================--
-- Standalone Hotel Framework
-- server/jobs.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Jobs = Hotel.Jobs or {}

Hotel.Jobs.Roles = Hotel.Jobs.Roles or {
    reception = {},
    cleaner = {},
    security = {},
    manager = {}
}

local function Notify(src, msg, t)
    Hotel.Notify(src, msg, t or "inform")
end

function Hotel.Jobs.SetRole(identifier, hotelId, role)
    if not identifier or not hotelId or not role then return false end

    Hotel.Jobs.Roles[role] = Hotel.Jobs.Roles[role] or {}
    Hotel.Jobs.Roles[role][identifier] = hotelId

    if MySQL then
        MySQL.insert.await([[
            INSERT INTO hotel_jobs (identifier, hotel, role)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE hotel = VALUES(hotel), role = VALUES(role)
        ]], {
            identifier,
            hotelId,
            role
        })
    end

    return true
end

function Hotel.Jobs.RemoveRole(identifier, role)
    if not identifier or not role then return false end

    if Hotel.Jobs.Roles[role] then
        Hotel.Jobs.Roles[role][identifier] = nil
    end

    if MySQL then
        MySQL.query.await(
            "DELETE FROM hotel_jobs WHERE identifier = ? AND role = ?",
            { identifier, role }
        )
    end

    return true
end

function Hotel.Jobs.HasRole(src, role, hotelId)
    local identifier = Hotel.GetIdentifier(src)
    if not identifier then return false end

    local assignedHotel =
        Hotel.Jobs.Roles[role]
        and Hotel.Jobs.Roles[role][identifier]

    if not assignedHotel then return false end

    if hotelId then
        return assignedHotel == hotelId
    end

    return true
end

function Hotel.Jobs.GetRole(identifier)
    for role, list in pairs(Hotel.Jobs.Roles) do
        if list[identifier] then
            return role, list[identifier]
        end
    end

    return nil, nil
end

RegisterNetEvent("hotel:setStaffRole", function(targetIdentifier, hotelId, role)
    local src = source

    if not Hotel.IsBoss(src, hotelId) then
        return Notify(src, "No permission.", "error")
    end

    if not targetIdentifier or not role then
        return Notify(src, "Missing staff identifier or role.", "error")
    end

    Hotel.Jobs.SetRole(targetIdentifier, hotelId, role)
    Notify(src, "Staff role updated.", "success")
end)

RegisterNetEvent("hotel:removeStaffRole", function(targetIdentifier, role)
    local src = source

    local _, hotelId = Hotel.Jobs.GetRole(targetIdentifier)

    if hotelId and not Hotel.IsBoss(src, hotelId) then
        return Notify(src, "No permission.", "error")
    end

    Hotel.Jobs.RemoveRole(targetIdentifier, role)
    Notify(src, "Staff role removed.", "success")
end)

RegisterNetEvent("hotel:getMyHotelJob", function()
    local src = source
    local identifier = Hotel.GetIdentifier(src)

    local role, hotelId = Hotel.Jobs.GetRole(identifier)

    TriggerClientEvent("hotel:receiveMyHotelJob", src, {
        role = role,
        hotel = hotelId
    })
end)

CreateThread(function()
    Wait(2500)

    if not MySQL then return end

    local rows = MySQL.query.await("SELECT * FROM hotel_jobs", {})

    for _, row in pairs(rows or {}) do
        Hotel.Jobs.Roles[row.role] = Hotel.Jobs.Roles[row.role] or {}
        Hotel.Jobs.Roles[row.role][row.identifier] = row.hotel
    end
end)

exports("SetHotelRole", Hotel.Jobs.SetRole)
exports("RemoveHotelRole", Hotel.Jobs.RemoveRole)
exports("HasHotelRole", Hotel.Jobs.HasRole)
exports("GetHotelRole", Hotel.Jobs.GetRole)
