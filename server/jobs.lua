local Roles = { reception = {}, cleaner = {}, security = {}, manager = {} }

local function Main() return require "server.main" end

---@param identifier string
---@param hotelId string
---@param role string
---@return boolean
local function SetRole(identifier, hotelId, role)
    if not identifier or not hotelId or not role then return false end
    Roles[role] = Roles[role] or {}
    Roles[role][identifier] = hotelId
    MySQL.insert.await(
        "INSERT INTO hotel_jobs (identifier, hotel, role) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE hotel = VALUES(hotel), role = VALUES(role)",
        { identifier, hotelId, role }
    )
    return true
end

---@param identifier string
---@param role string
---@return boolean
local function RemoveRole(identifier, role)
    if not identifier or not role then return false end
    if Roles[role] then Roles[role][identifier] = nil end
    MySQL.query.await("DELETE FROM hotel_jobs WHERE identifier = ? AND role = ?", { identifier, role })
    return true
end

---@param src number
---@param role string
---@param hotelId? string
---@return boolean
local function HasRole(src, role, hotelId)
    local identifier = Main().GetIdentifier(src)
    if not identifier then return false end
    local assigned = Roles[role] and Roles[role][identifier]
    if not assigned then return false end
    if hotelId then return assigned == hotelId end
    return true
end

---@param identifier string
---@return string|nil, string|nil
local function GetRole(identifier)
    for role, list in pairs(Roles) do
        if list[identifier] then return role, list[identifier] end
    end
    return nil, nil
end

RegisterNetEvent("hotel:setStaffRole", function(targetIdentifier, hotelId, role)
    local src = source
    if not (require "server.boss").IsBoss(src, hotelId) then return Main().Notify(src, "No permission.", "error") end
    if not targetIdentifier or not role then return Main().Notify(src, "Missing data.", "error") end
    SetRole(targetIdentifier, hotelId, role)
    Main().Notify(src, "Staff role updated.", "success")
end)

RegisterNetEvent("hotel:removeStaffRole", function(targetIdentifier, role)
    local src      = source
    local _, hotel = GetRole(targetIdentifier)
    if hotel and not (require "server.boss").IsBoss(src, hotel) then
        return Main().Notify(src, "No permission.", "error")
    end
    RemoveRole(targetIdentifier, role)
    Main().Notify(src, "Staff role removed.", "success")
end)

lib.callback.register("hotel:getMyHotelJob", function(src)
    local identifier  = Main().GetIdentifier(src)
    local role, hotel = GetRole(identifier)
    return { role = role, hotel = hotel }
end)

CreateThread(function()
    Wait(2500)
    local rows = MySQL.query.await("SELECT * FROM hotel_jobs", {})
    for _, row in pairs(rows or {}) do
        Roles[row.role] = Roles[row.role] or {}
        Roles[row.role][row.identifier] = row.hotel
    end
end)

exports("SetHotelRole",    SetRole)
exports("RemoveHotelRole", RemoveRole)
exports("HasHotelRole",    HasRole)
exports("GetHotelRole",    GetRole)

return { SetRole = SetRole, RemoveRole = RemoveRole, HasRole = HasRole, GetRole = GetRole, Roles = Roles }
