--========================================================--
-- Standalone Hotel Framework
-- client/complaints.lua
--========================================================--

local Complaints = {
    open = false,
    hotelId = nil
}

local function Notify(msg)
    TriggerEvent("hotel:notify", msg)
end

local function OpenComplaintMenu(hotelId)
    Complaints.open = true
    Complaints.hotelId = hotelId

    SetNuiFocus(true, true)

    SendNUIMessage({
        action = "openComplaint",
        data = {
            hotel = hotelId,
            categories = {
                "Noise complaint",
                "Room issue",
                "Lost key",
                "Staff complaint",
                "Rule break",
                "Other"
            }
        }
    })
end

local function CloseComplaintMenu()
    Complaints.open = false
    Complaints.hotelId = nil

    SetNuiFocus(false, false)

    SendNUIMessage({
        action = "closeComplaint"
    })
end

RegisterNetEvent("hotel:openComplaintMenu", function(hotelId)
    OpenComplaintMenu(hotelId)
end)

RegisterNUICallback("complaintClose", function(_, cb)
    CloseComplaintMenu()
    cb({ ok = true })
end)

RegisterNUICallback("submitComplaint", function(data, cb)
    if not Complaints.hotelId then
        cb({ ok = false, error = "No hotel selected" })
        return
    end

    if not data or not data.message or data.message == "" then
        cb({ ok = false, error = "Message required" })
        return
    end

    TriggerServerEvent("hotel:submitComplaint", {
        hotel = Complaints.hotelId,
        category = data.category or "Other",
        message = data.message,
        roomId = tonumber(data.roomId)
    })

    Notify("Complaint submitted.")
    CloseComplaintMenu()

    cb({ ok = true })
end)

RegisterNetEvent("hotel:complaintSubmitted", function()
    Notify("Your complaint has been received.")
end)

RegisterNetEvent("hotel:complaintResolved", function(id)
    Notify(("Complaint #%s has been resolved."):format(id))
end)

RegisterCommand("hotel_complain", function(_, args)
    local hotelId = args[1] or "main_hotel"
    OpenComplaintMenu(hotelId)
end)

exports("OpenComplaintMenu", OpenComplaintMenu)
exports("CloseComplaintMenu", CloseComplaintMenu)
