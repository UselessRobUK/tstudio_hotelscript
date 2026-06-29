--========================================================--
-- Standalone Hotel Framework
-- server/payments.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Payments = {}

local Accounts = {
    cash = {},
    bank = {}
}

local function Identifier(src)
    return Hotel.GetIdentifier(src)
end

local function Notify(src, msg, t)
    if Hotel.Notify then
        Hotel.Notify(src, msg, t or "inform")
    end
end

local function GetAccount(account)
    account = account or "cash"

    if account ~= "cash" and account ~= "bank" then
        account = "cash"
    end

    return account
end

function Hotel.Payments.GetMoney(src, account)
    account = GetAccount(account)

    if Config.Debug then
        return 999999999
    end

    local identifier = Identifier(src)
    if not identifier then return 0 end

    Accounts[account][identifier] = Accounts[account][identifier] or 0

    return Accounts[account][identifier]
end

function Hotel.Payments.AddMoney(src, amount, account, reason)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end

    account = GetAccount(account)

    local identifier = Identifier(src)
    if not identifier then return false end

    Accounts[account][identifier] = Accounts[account][identifier] or 0
    Accounts[account][identifier] = Accounts[account][identifier] + amount

    if Config.Debug then
        print(("[HOTEL PAYMENT] Added %s to %s (%s) | %s"):format(
            amount,
            identifier,
            account,
            reason or "no reason"
        ))
    end

    return true
end

function Hotel.Payments.RemoveMoney(src, amount, account, reason)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end

    account = GetAccount(account)

    if Config.Debug then
        print(("[HOTEL PAYMENT] Removed %s from player %s (%s) | %s"):format(
            amount,
            src,
            account,
            reason or "no reason"
        ))

        return true
    end

    local identifier = Identifier(src)
    if not identifier then return false end

    Accounts[account][identifier] = Accounts[account][identifier] or 0

    if Accounts[account][identifier] < amount then
        return false
    end

    Accounts[account][identifier] = Accounts[account][identifier] - amount

    return true
end

function Hotel.Payments.TransferToHotel(src, hotelId, amount, account, reason)
    if not Hotel.Payments.RemoveMoney(src, amount, account, reason) then
        return false
    end

    Hotel.Revenue[hotelId] = (Hotel.Revenue[hotelId] or 0) + amount

    return true
end

RegisterNetEvent("hotel:addMoney", function(amount, account)
    local src = source
    Hotel.Payments.AddMoney(src, amount, account, "manual")
end)

RegisterNetEvent("hotel:getBalance", function(account)
    local src = source
    local balance = Hotel.Payments.GetMoney(src, account)

    TriggerClientEvent("hotel:receiveBalance", src, account or "cash", balance)
end)

exports("GetMoney", Hotel.Payments.GetMoney)
exports("AddMoney", Hotel.Payments.AddMoney)
exports("RemoveMoney", Hotel.Payments.RemoveMoney)
exports("TransferToHotel", Hotel.Payments.TransferToHotel)
