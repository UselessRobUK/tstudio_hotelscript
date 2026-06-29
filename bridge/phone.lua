local type = "standalone"

if GetResourceState("lb-phone") == "started" then
    type = "lb"
elseif GetResourceState("qb-phone") == "started" then
    type = "qb"
elseif GetResourceState("qs-smartphone") == "started" then
    type = "qs"
elseif GetResourceState("gksphone") == "started" then
    type = "gks"
elseif GetResourceState("gcphone") == "started" then
    type = "gc"
end

---@param src number
---@param title string
---@param message string
local function Notify(src, title, message)
    title   = title or "Hotel"
    message = message or ""

    if type == "lb" then
        exports["lb-phone"]:SendNotification(src, { app = "Hotel", title = title, content = message })
        return
    elseif type == "qb" then
        TriggerClientEvent("qb-phone:client:CustomNotification", src, title, message, "fas fa-hotel")
        return
    elseif type == "qs" then
        TriggerClientEvent("qs-smartphone:client:notify", src, title, message)
        return
    elseif type == "gks" then
        TriggerClientEvent("gksphone:notifi", src, { title = title, message = message })
        return
    elseif type == "gc" then
        TriggerClientEvent("gcPhone:notify", src, title, message)
        return
    end

    TriggerClientEvent("chat:addMessage", src, {
        color     = { 52, 152, 219 },
        multiline = true,
        args      = { title, message },
    })
end

---@param src number
---@param hotelName string
---@param roomNumber number
local function Booking(src, hotelName, roomNumber)
    Notify(src, "Hotel Booking", ("Reservation confirmed.\n%s\nRoom %s"):format(hotelName, roomNumber))
end

---@param src number
---@param hotelName string
---@param hoursLeft number
local function Reminder(src, hotelName, hoursLeft)
    Notify(src, "Hotel Reminder", ("%s expires in %s hour(s)."):format(hotelName, hoursLeft))
end

---@param src number
local function Eviction(src)
    Notify(src, "Hotel", "Your hotel rental has ended.")
end

return {
    type     = type,
    Notify   = Notify,
    Booking  = Booking,
    Reminder = Reminder,
    Eviction = Eviction,
}
