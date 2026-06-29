local type = "standalone"

if GetResourceState("Renewed-Banking") == "started" then
    type = "renewed"
elseif GetResourceState("okokBanking") == "started" then
    type = "okok"
elseif GetResourceState("qb-banking") == "started" then
    type = "qb"
elseif GetResourceState("esx_banking") == "started" then
    type = "esx"
end

---@param src number
---@param amount number
---@param account? string
---@return boolean
local function Remove(src, amount, account)
    amount  = tonumber(amount) or 0
    account = account or "bank"
    if amount <= 0 then return false end

    if type == "qb" then
        local QBCore = exports["qb-core"]:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return false end
        return Player.Functions.RemoveMoney(account, amount, "hotel payment")
    end

    if type == "renewed" then
        return exports["Renewed-Banking"]:removeAccountMoney(account, amount)
    end

    return exports[GetCurrentResourceName()]:RemoveMoney(src, amount, account, "hotel payment")
end

---@param src number
---@param amount number
---@param account? string
---@return boolean
local function Add(src, amount, account)
    amount  = tonumber(amount) or 0
    account = account or "bank"
    if amount <= 0 then return false end

    if type == "qb" then
        local QBCore = exports["qb-core"]:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return false end
        return Player.Functions.AddMoney(account, amount, "hotel payout")
    end

    return exports[GetCurrentResourceName()]:AddMoney(src, amount, account, "hotel payout")
end

---@param src number
---@param account? string
---@return number
local function Get(src, account)
    account = account or "bank"

    if type == "qb" then
        local QBCore = exports["qb-core"]:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return 0 end
        return Player.PlayerData.money[account] or 0
    end

    return 0
end

return {
    type   = type,
    Remove = Remove,
    Add    = Add,
    Get    = Get,
}
