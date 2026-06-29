local Config = require "configs.shared.main"

local Bank = { balances = {}, transactions = {} }

local function Identifier(src)
    return (require "server.main").GetIdentifier(src)
end

---@param src number
---@return number
local function GetBalance(src)
    local identifier = Identifier(src)
    if not identifier then return 0 end
    Bank.balances[identifier] = Bank.balances[identifier] or 0
    return Bank.balances[identifier]
end

---@param src number
---@param amount number
---@return boolean
local function SetBalance(src, amount)
    local identifier = Identifier(src)
    if not identifier then return false end
    Bank.balances[identifier] = tonumber(amount) or 0
    return true
end

---@param identifier string
---@param amount number
---@param txType string
---@param reason? string
local function Log(identifier, amount, txType, reason)
    local tx = {
        identifier = identifier,
        amount     = tonumber(amount) or 0,
        type       = txType or "unknown",
        reason     = reason or "N/A",
        time       = os.time(),
    }
    Bank.transactions[#Bank.transactions + 1] = tx
    MySQL.insert.await(
        "INSERT INTO hotel_transactions (identifier, amount, type, reason, created_at) VALUES (?, ?, ?, ?, ?)",
        { tx.identifier, tx.amount, tx.type, tx.reason, tx.time }
    )
end

---@param src number
---@param amount number
---@param reason? string
---@return boolean
local function Add(src, amount, reason)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end
    local identifier = Identifier(src)
    if not identifier then return false end
    Bank.balances[identifier] = (Bank.balances[identifier] or 0) + amount
    Log(identifier, amount, "credit", reason)
    return true
end

---@param src number
---@param amount number
---@param reason? string
---@return boolean
local function Remove(src, amount, reason)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end
    if Config.Debug then
        Log(("debug:%s"):format(src), amount, "debit", reason or "debug payment")
        return true
    end
    local identifier = Identifier(src)
    if not identifier then return false end
    Bank.balances[identifier] = Bank.balances[identifier] or 0
    if Bank.balances[identifier] < amount then return false end
    Bank.balances[identifier] = Bank.balances[identifier] - amount
    Log(identifier, amount, "debit", reason)
    return true
end

---@param src number
---@param target number
---@param amount number
---@param reason? string
---@return boolean
local function Transfer(src, target, amount, reason)
    if not Remove(src, amount, reason or "transfer") then return false end
    Add(target, amount, reason or "transfer")
    return true
end

RegisterNetEvent("hotel:bank:getBalance", function()
    TriggerClientEvent("hotel:bank:balance", source, GetBalance(source))
end)

RegisterNetEvent("hotel:bank:depositDebug", function(amount)
    if not Config.Debug then return end
    Add(source, tonumber(amount) or 0, "debug deposit")
end)

exports("GetBankBalance", GetBalance)
exports("SetBankBalance", SetBalance)
exports("AddBank",        Add)
exports("RemoveBank",     Remove)
exports("TransferBank",   Transfer)

return { GetBalance = GetBalance, SetBalance = SetBalance, Add = Add, Remove = Remove, Transfer = Transfer }
