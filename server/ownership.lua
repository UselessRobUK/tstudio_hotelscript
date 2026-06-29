local Hotels = {}

local function Main() return require "server.main" end

---@param hotelId string
---@return string|nil
local function GetOwner(hotelId)
    return Hotels[hotelId] and Hotels[hotelId].owner or nil
end

---@param src number
---@param hotelId string
---@return boolean
local function IsOwner(src, hotelId)
    local identifier = Main().GetIdentifier(src)
    if not identifier then return false end
    return GetOwner(hotelId) == identifier
end

---@param hotelId string
---@param identifier string
---@return boolean
local function SetOwner(hotelId, identifier)
    Hotels[hotelId] = Hotels[hotelId] or { balance = 0, reputation = 50 }
    Hotels[hotelId].owner = identifier
    MySQL.insert.await(
        "INSERT INTO hotel_ownership (hotel, owner, balance, reputation) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE owner = VALUES(owner)",
        { hotelId, identifier, Hotels[hotelId].balance or 0, Hotels[hotelId].reputation or 50 }
    )
    return true
end

---@param hotelId string
---@param amount number
---@return boolean
local function AddBalance(hotelId, amount)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end
    Hotels[hotelId] = Hotels[hotelId] or { balance = 0, reputation = 50 }
    Hotels[hotelId].balance = (Hotels[hotelId].balance or 0) + amount
    MySQL.update.await("UPDATE hotel_ownership SET balance = ? WHERE hotel = ?", { Hotels[hotelId].balance, hotelId })
    return true
end

---@param hotelId string
---@param amount number
---@return boolean
local function RemoveBalance(hotelId, amount)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end
    local hotel = Hotels[hotelId]
    if not hotel or (hotel.balance or 0) < amount then return false end
    hotel.balance = hotel.balance - amount
    MySQL.update.await("UPDATE hotel_ownership SET balance = ? WHERE hotel = ?", { hotel.balance, hotelId })
    return true
end

---@param hotelId string
---@return number
local function GetBalance(hotelId)
    return Hotels[hotelId] and Hotels[hotelId].balance or 0
end

RegisterNetEvent("hotel:setOwner", function(hotelId, targetIdentifier)
    local src = source
    if not hotelId or not targetIdentifier then return Main().Notify(src, "Missing hotel or identifier.", "error") end
    SetOwner(hotelId, targetIdentifier)
    Main().Notify(src, "Hotel owner updated.", "success")
end)

RegisterNetEvent("hotel:withdrawHotelFunds", function(hotelId, amount)
    local src = source
    amount = tonumber(amount) or 0
    if not IsOwner(src, hotelId) then return Main().Notify(src, "No permission.", "error") end
    if not RemoveBalance(hotelId, amount) then return Main().Notify(src, "Insufficient hotel balance.", "error") end
    exports[GetCurrentResourceName()]:AddMoney(src, amount, "bank", "hotel withdrawal")
    Main().Notify(src, "Funds withdrawn.", "success")
end)

RegisterNetEvent("hotel:depositHotelFunds", function(hotelId, amount)
    local src = source
    amount = tonumber(amount) or 0
    if not IsOwner(src, hotelId) then return Main().Notify(src, "No permission.", "error") end
    if not exports[GetCurrentResourceName()]:RemoveMoney(src, amount, "bank", "hotel deposit") then
        return Main().Notify(src, "Not enough money.", "error")
    end
    AddBalance(hotelId, amount)
    Main().Notify(src, "Funds deposited.", "success")
end)

CreateThread(function()
    Wait(2500)
    local rows = MySQL.query.await("SELECT * FROM hotel_ownership", {})
    for _, row in pairs(rows or {}) do
        Hotels[row.hotel] = { owner = row.owner, balance = tonumber(row.balance) or 0, reputation = tonumber(row.reputation) or 50 }
    end
end)

exports("SetHotelOwner",      SetOwner)
exports("GetHotelOwner",      GetOwner)
exports("IsHotelOwner",       IsOwner)
exports("AddHotelBalance",    AddBalance)
exports("RemoveHotelBalance", RemoveBalance)
exports("GetHotelBalance",    GetBalance)

return { GetOwner = GetOwner, IsOwner = IsOwner, SetOwner = SetOwner, GetBalance = GetBalance }
