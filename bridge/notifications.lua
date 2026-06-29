local type = "standalone"

if GetResourceState("ox_lib") == "started" then
    type = "ox"
elseif GetResourceState("okokNotify") == "started" then
    type = "okok"
elseif GetResourceState("mythic_notify") == "started" then
    type = "mythic"
elseif GetResourceState("qb-core") == "started" then
    type = "qb"
elseif GetResourceState("es_extended") == "started" then
    type = "esx"
end

---@param src number
---@param message string
---@param notifyType? string
---@param duration? number
local function Send(src, message, notifyType, duration)
    TriggerClientEvent("hotel:notify", src, message, notifyType or "inform", duration or 5000)
end

---@param src number
---@param message string
local function Success(src, message) Send(src, message, "success") end

---@param src number
---@param message string
local function Error(src, message) Send(src, message, "error") end

---@param src number
---@param message string
local function Warning(src, message) Send(src, message, "warning") end

---@param src number
---@param message string
local function Info(src, message) Send(src, message, "inform") end

return {
    type    = type,
    Send    = Send,
    Success = Success,
    Error   = Error,
    Warning = Warning,
    Info    = Info,
}
