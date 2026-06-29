--========================================================--
-- Standalone Hotel Framework
-- server/employees.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Employees = Hotel.Employees or {}

local function Notify(src, msg, t)
    Hotel.Notify(src, msg, t or "inform")
end

function Hotel.Employees.GetEmployees(hotelId)
    local list = {}

    if not Hotel.Jobs or not Hotel.Jobs.Roles then
        return list
    end

    for role, employees in pairs(Hotel.Jobs.Roles) do
        for identifier, assignedHotel in pairs(employees) do
            if assignedHotel == hotelId then
                list[#list + 1] = {
                    identifier = identifier,
                    hotel = hotelId,
                    role = role
                }
            end
        end
    end

    return list
end

function Hotel.Employees.Hire(src, targetIdentifier, hotelId, role)
    if not Hotel.IsBoss(src, hotelId) then
        return false, "No permission"
    end

    role = role or "reception"

    if not Hotel.Jobs or not Hotel.Jobs.SetRole then
        return false, "Jobs module not loaded"
    end

    Hotel.Jobs.SetRole(targetIdentifier, hotelId, role)
    return true
end

function Hotel.Employees.Fire(src, targetIdentifier, hotelId)
    if not Hotel.IsBoss(src, hotelId) then
        return false, "No permission"
    end

    local role = nil

    if Hotel.Jobs and Hotel.Jobs.GetRole then
        role = Hotel.Jobs.GetRole(targetIdentifier)
    end

    if role then
        Hotel.Jobs.RemoveRole(targetIdentifier, role)
    end

    return true
end

RegisterNetEvent("hotel:getEmployees", function(hotelId)
    local src = source

    if not Hotel.IsBoss(src, hotelId) then
        return Notify(src, "No permission.", "error")
    end

    TriggerClientEvent(
        "hotel:receiveEmployees",
        src,
        hotelId,
        Hotel.Employees.GetEmployees(hotelId)
    )
end)

RegisterNetEvent("hotel:hireEmployee", function(hotelId, targetIdentifier, role)
    local src = source

    local ok, err = Hotel.Employees.Hire(
        src,
        targetIdentifier,
        hotelId,
        role
    )

    if not ok then
        return Notify(src, err or "Could not hire employee.", "error")
    end

    Notify(src, "Employee hired.", "success")
end)

RegisterNetEvent("hotel:fireEmployee", function(hotelId, targetIdentifier)
    local src = source

    local ok, err = Hotel.Employees.Fire(
        src,
        targetIdentifier,
        hotelId
    )

    if not ok then
        return Notify(src, err or "Could not fire employee.", "error")
    end

    Notify(src, "Employee fired.", "success")
end)

exports("GetHotelEmployees", Hotel.Employees.GetEmployees)
exports("HireHotelEmployee", Hotel.Employees.Hire)
exports("FireHotelEmployee", Hotel.Employees.Fire)
