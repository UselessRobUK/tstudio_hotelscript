local function Main() return require "server.main" end
local function Jobs() return require "server.jobs" end
local function Boss() return require "server.boss" end

---@param hotelId string
---@return table
local function GetEmployees(hotelId)
    local list  = {}
    local Roles = Jobs().Roles
    for role, employees in pairs(Roles) do
        for identifier, assignedHotel in pairs(employees) do
            if assignedHotel == hotelId then
                list[#list + 1] = { identifier = identifier, hotel = hotelId, role = role }
            end
        end
    end
    return list
end

---@param src number
---@param targetIdentifier string
---@param hotelId string
---@param role? string
---@return boolean, string?
local function Hire(src, targetIdentifier, hotelId, role)
    if not Boss().IsBoss(src, hotelId) then return false, "No permission" end
    Jobs().SetRole(targetIdentifier, hotelId, role or "reception")
    return true
end

---@param src number
---@param targetIdentifier string
---@param hotelId string
---@return boolean, string?
local function Fire(src, targetIdentifier, hotelId)
    if not Boss().IsBoss(src, hotelId) then return false, "No permission" end
    local role = Jobs().GetRole(targetIdentifier)
    if role then Jobs().RemoveRole(targetIdentifier, role) end
    return true
end

RegisterNetEvent("hotel:getEmployees", function(hotelId)
    local src = source
    if not Boss().IsBoss(src, hotelId) then return Main().Notify(src, "No permission.", "error") end
    TriggerClientEvent("hotel:receiveEmployees", src, hotelId, GetEmployees(hotelId))
end)

RegisterNetEvent("hotel:hireEmployee", function(hotelId, targetIdentifier, role)
    local src   = source
    local ok, err = Hire(src, targetIdentifier, hotelId, role)
    if not ok then return Main().Notify(src, err or "Could not hire employee.", "error") end
    Main().Notify(src, "Employee hired.", "success")
end)

RegisterNetEvent("hotel:fireEmployee", function(hotelId, targetIdentifier)
    local src   = source
    local ok, err = Fire(src, targetIdentifier, hotelId)
    if not ok then return Main().Notify(src, err or "Could not fire employee.", "error") end
    Main().Notify(src, "Employee fired.", "success")
end)

exports("GetHotelEmployees", GetEmployees)
exports("HireHotelEmployee", Hire)
exports("FireHotelEmployee", Fire)

return { GetEmployees = GetEmployees, Hire = Hire, Fire = Fire }
