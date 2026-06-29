local Config = require "configs.shared.main"

local Colors = { success = 5763719, error = 15548997, warning = 16776960, info = 3447003 }

---@param name string
---@return string|nil
local function GetUrl(name)
    if not Config.Webhooks then return nil end
    return Config.Webhooks[name] or Config.Webhooks.default
end

---@param webhookName string
---@param title string
---@param description string
---@param color? number
local function Send(webhookName, title, description, color)
    local url = GetUrl(webhookName)
    if not url or url == "" then return end

    PerformHttpRequest(url, function() end, "POST", json.encode({
        username = "Hotel Framework",
        embeds = {
            {
                title       = title,
                description = description,
                color       = color or Colors.info,
                footer      = { text = os.date("%d/%m/%Y %H:%M:%S") },
                timestamp   = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            },
        },
    }), { ["Content-Type"] = "application/json" })
end

---@param player string
---@param hotel string
---@param room number
local function Rental(player, hotel, room)
    Send("rentals", "Room Rented", ("**Player:** %s\n**Hotel:** %s\n**Room:** %s"):format(player, hotel, room), Colors.success)
end

---@param player string
---@param hotel string
---@param message string
local function Complaint(player, hotel, message)
    Send("complaints", "Complaint Submitted", ("**Player:** %s\n**Hotel:** %s\n\n%s"):format(player, hotel, message), Colors.warning)
end

---@param player string
---@param hotel string
local function Eviction(player, hotel)
    Send("staff", "Player Evicted", ("**Player:** %s\n**Hotel:** %s"):format(player, hotel), Colors.error)
end

exports("SendHotelWebhook",       Send)
exports("HotelWebhookRental",     Rental)
exports("HotelWebhookComplaint",  Complaint)
exports("HotelWebhookEviction",   Eviction)

return { Send = Send, Rental = Rental, Complaint = Complaint, Eviction = Eviction }
