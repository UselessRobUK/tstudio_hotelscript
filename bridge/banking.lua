--========================================================--
-- Standalone Hotel Framework
-- bridge/banking.lua
--========================================================--

Bridge = Bridge or {}
Bridge.Banking = Bridge.Banking or {}

Bridge.Banking.Type = "standalone"

if GetResourceState("Renewed-Banking") == "started" then
    Bridge.Banking.Type = "renewed"
elseif GetResourceState("okokBanking") == "started" then
    Bridge.Banking.Type = "okok"
elseif GetResourceState("qb-banking") == "started" then
    Bridge.Banking.Type = "qb"
elseif GetResourceState("esx_banking") == "started" then
    Bridge.Banking.Type = "esx"
end

function Bridge.Banking.Remove(src, amount, account)
    amount = tonumber(amount) or 0
    account = account or "bank"

    if amount <= 0 then return false end

    if Bridge.Banking.Type == "standalone" then
        return exports[GetCurrentResourceName()]:RemoveMoney(src, amount, account, "hotel payment")
    end

    if Bridge.Banking.Type == "qb" then
        local QBCore = exports["qb-core"]:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return false end
        return Player.Functions.RemoveMoney(account, amount, "hotel payment")
    end

    if Bridge.Banking.Type == "renewed" then
        return exports["Renewed-Banking"]:removeAccountMoney(account, amount)
    end

    return exports[GetCurrentResourceName()]:RemoveMoney(src, amount, account, "hotel payment")
end

function Bridge.Banking.Add(src, amount, account)
    amount = tonumber(amount) or 0
    account = account or "bank"

    if amount <= 0 then return false end

    if Bridge.Banking.Type == "standalone" then
        return exports[GetCurrentResourceName()]:AddMoney(src, amount, account, "hotel payout")
    end

    if Bridge.Banking.Type == "qb" then
        local QBCore = exports["qb-core"]:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return false end
        return Player.Functions.AddMoney(account, amount, "hotel payout")
    end

    return exports[GetCurrentResourceName()]:AddMoney(src, amount, account, "hotel payout")
end

function Bridge.Banking.Get(src, account)
    account = account or "bank"

    if Bridge.Banking.Type == "standalone" then
        return exports[GetCurrentResourceName()]:GetMoney(src, account)
    end

    if Bridge.Banking.Type == "qb" then
        local QBCore = exports["qb-core"]:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return 0 end
        return Player.PlayerData.money[account] or 0
    end

    return 0
end

exports("BridgeBankingRemove", Bridge.Banking.Remove)
exports("BridgeBankingAdd", Bridge.Banking.Add)
exports("BridgeBankingGet", Bridge.Banking.Get)
