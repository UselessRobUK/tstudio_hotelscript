local Config = require "configs.shared.main"
local State  = require "server.state"

local Accounts = { cash = {}, bank = {} }

local function Identifier(src)
    return (require "server.main").GetIdentifier(src)
end

local function GetAccount(account)
    account = account or "cash"
    if account ~= "cash" and account ~= "bank" then account = "cash" end
    return account
end

---@param src number
---@param account? string
---@return number
local function GetMoney(src, account)
    account = GetAccount(account)
    if Config.Debug then return 999999999 end
    local identifier = Identifier(src)
    if not identifier then return 0 end
    Accounts[account][identifier] = Accounts[account][identifier] or 0
    return Accounts[account][identifier]
end

---@param src number
---@param amount number
---@param account? string
---@param reason? string
---@return boolean
local function AddMoney(src, amount, account, reason)
    amount  = tonumber(amount) or 0
    account = GetAccount(account)
    if amount <= 0 then return false end
    local identifier = Identifier(src)
    if not identifier then return false end
    Accounts[account][identifier] = (Accounts[account][identifier] or 0) + amount
    return true
end

---@param src number
---@param amount number
---@param account? string
---@param reason? string
---@return boolean
local function RemoveMoney(src, amount, account, reason)
    amount  = tonumber(amount) or 0
    account = GetAccount(account)
    if amount <= 0 then return false end
    if Config.Debug then return true end
    local identifier = Identifier(src)
    if not identifier then return false end
    Accounts[account][identifier] = Accounts[account][identifier] or 0
    if Accounts[account][identifier] < amount then return false end
    Accounts[account][identifier] = Accounts[account][identifier] - amount
    return true
end

---@param src number
---@param hotelId string
---@param amount number
---@param account? string
---@param reason? string
---@return boolean
local function TransferToHotel(src, hotelId, amount, account, reason)
    if not RemoveMoney(src, amount, account, reason) then return false end
    State.Revenue[hotelId] = (State.Revenue[hotelId] or 0) + amount
    return true
end

lib.callback.register("hotel:getBalance", function(src, account)
    return { account = account or "cash", balance = GetMoney(src, account) }
end)

exports("GetMoney",         GetMoney)
exports("AddMoney",         AddMoney)
exports("RemoveMoney",      RemoveMoney)
exports("TransferToHotel",  TransferToHotel)

return { GetMoney = GetMoney, AddMoney = AddMoney, RemoveMoney = RemoveMoney, TransferToHotel = TransferToHotel }
