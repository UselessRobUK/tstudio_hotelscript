local type = "standalone"

if GetResourceState("illenium-appearance") == "started" then
    type = "illenium"
elseif GetResourceState("fivem-appearance") == "started" then
    type = "fivem"
elseif GetResourceState("qb-clothing") == "started" then
    type = "qb"
elseif GetResourceState("esx_skin") == "started" then
    type = "esx"
elseif GetResourceState("rcore_clothing") == "started" then
    type = "rcore"
end

---@param src number
---@return boolean
local function Open(src)
    TriggerClientEvent("hotel:wardrobeApproved", src)
    return true
end

return {
    type = type,
    Open = Open,
}
