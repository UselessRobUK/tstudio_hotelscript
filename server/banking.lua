--========================================================--
-- Standalone Hotel Framework
-- server/banking.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Banking = {}

local Bank = {
    balances = {},
    transactions = {}
}

local function Identifier(src)
    return Hotel.GetIdentifier(src)
end

function Hotel.Banking.GetBalance(src)
    local identifier = Identifier(src)
    if not identifier then return 0 end

    Bank.balances[identifier] = Bank.balances[identifier] or 0
    return Bank.balances[identifier]
end

function Hotel.Banking.SetBalance(src, amount)
    local identifier = Identifier(src)
    if not identifier then return false end

    Bank.balances[identifier] = tonumber(amount) or 0
    return true
end

function Hotel.Banking.Add(src, amount, reason)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end

    local identifier = Identifier(src)
    if not identifier then return false end

    Bank.balances[identifier] = Bank.balances[identifier] or 0
    Bank.balances[identifier] = Bank.balances[identifier] + amount

    Hotel.Banking.Log(identifier, amount, "credit", reason)

    return true
end

function Hotel.Banking.Remove(src, amount, reason)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end

    if Config.Debug then
        Hotel.Banking.Log(
            ("debug:%s"):format(src),
            amount,
            "debit",
            reason or "debug payment"
        )
        return true
    end

    local identifier = Identifier(src)
    if not identifier then return false end

    Bank.balances[identifier] = Bank.balances[identifier] or 0

    if Bank.balances[identifier] < amount then
        return false
    end

    Bank.balances[identifier] = Bank.balances[identifier] - amount

    Hotel.Banking.Log(identifier, amount, "debit", reason)

    return true
end

function Hotel.Banking.Transfer(src, target, amount, reason)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end

    if not Hotel.Banking.Remove(src, amount, reason or "transfer") then
        return false
    end

    Hotel.Banking.Add(target, amount, reason or "transfer")
    return true
end

function Hotel.Banking.Log(identifier, amount, txType, reason)
    local tx = {
        identifier = identifier,
        amount = tonumber(amount) or 0,
        type = txType or "unknown",
        reason = reason or "N/A",
        time = os.time()
    }

    Bank.transactions[#Bank.transactions + 1] = tx

    if MySQL then
        MySQL.insert.await([[
            INSERT INTO hotel_transactions
            (identifier, amount, type, reason, created_at)
            VALUES (?, ?, ?, ?, ?)
        ]], {
            identifier,
            tx.amount,
            tx.type,
            tx.reason,
            tx.time
        })
    end
end

RegisterNetEvent("hotel:bank:getBalance", function()
    local src = source

    TriggerClientEvent(
        "hotel:bank:balance",
        src,
        Hotel.Banking.GetBalance(src)
    )
end)

RegisterNetEvent("hotel:bank:depositDebug", function(amount)
    local src = source

    if not Config.Debug then return end

    Hotel.Banking.Add(src, tonumber(amount) or 0, "debug deposit")
end)

exports("GetBankBalance", Hotel.Banking.GetBalance)
exports("SetBankBalance", Hotel.Banking.SetBalance)
exports("AddBank", Hotel.Banking.Add)
exports("RemoveBank", Hotel.Banking.Remove)
exports("TransferBank", Hotel.Banking.Transfer)
