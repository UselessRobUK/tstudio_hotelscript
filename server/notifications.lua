---@param src number
---@param message string
---@param notifyType? string
local function Notify(src, message, notifyType)
    if not src then return end
    TriggerClientEvent("hotel:notify", src, tostring(message), notifyType or "inform")
end

---@param message string
local function NotifyAll(message)
    TriggerClientEvent("hotel:notify", -1, tostring(message), "inform")
end

---@param title string
---@param message string
local function Announcement(title, message)
    TriggerClientEvent("hotel:announcement", -1, title, message)
end

RegisterNetEvent("hotel:testNotify",       function() Notify(source, "Notification test.") end)
RegisterNetEvent("hotel:testAnnouncement", function() Announcement("Hotel", "Welcome to the hotel!") end)

exports("Notify",        Notify)
exports("NotifyAll",     NotifyAll)
exports("Announcement",  Announcement)

return { Notify = Notify, NotifyAll = NotifyAll, Announcement = Announcement }
