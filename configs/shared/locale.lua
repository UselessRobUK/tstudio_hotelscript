local locales = {
    en = {
        welcome   = "Welcome",
        loading   = "Loading...",
        close     = "Close",
        back      = "Back",
        confirm   = "Confirm",
        cancel    = "Cancel",
        search    = "Search",
        save      = "Save",
        delete    = "Delete",
        edit      = "Edit",
        create    = "Create",

        hotel      = "Hotel",
        hotels     = "Hotels",
        reception  = "Reception",
        receptionist = "Receptionist",
        lobby      = "Lobby",
        room       = "Room",
        rooms      = "Rooms",
        available  = "Available",
        unavailable = "Occupied",

        rent_room        = "Rent Room",
        extend_room      = "Extend Rental",
        cancel_rental    = "Cancel Rental",
        room_rented      = "Room rented successfully.",
        room_extended    = "Rental extended.",
        rental_cancelled = "Rental cancelled.",
        already_renting  = "You already have an active room.",
        room_unavailable = "Room unavailable.",

        booking          = "Booking",
        bookings         = "Bookings",
        create_booking   = "Create Booking",
        booking_success  = "Booking created.",
        booking_failed   = "Booking failed.",
        booking_cancelled = "Booking cancelled.",

        room_key       = "Room Key",
        key_received   = "Room key received.",
        key_removed    = "Room key removed.",
        duplicate_key  = "Duplicate Key",
        no_key         = "You don't own this room key.",

        payment          = "Payment",
        cash             = "Cash",
        bank             = "Bank",
        insufficient_funds = "Insufficient funds.",
        payment_success  = "Payment successful.",

        boss_menu  = "Hotel Management",
        employees  = "Employees",
        revenue    = "Revenue",
        complaints = "Complaints",
        fines      = "Fines",
        evict      = "Evict Tenant",
        set_price  = "Change Room Price",
        hire       = "Hire Employee",
        fire       = "Fire Employee",

        room_clean = "Room cleaned.",
        room_dirty = "Room needs cleaning.",
        cleaning   = "Cleaning",

        stash    = "Storage",
        wardrobe = "Wardrobe",

        access_denied  = "Access denied.",
        invalid_room   = "Invalid room.",
        invalid_hotel  = "Invalid hotel.",
        no_permission  = "You don't have permission.",
        invalid_input  = "Invalid input.",

        success     = "Success",
        error       = "Error",
        warning     = "Warning",
        information = "Information",
    },
}

---@param key string
---@param ... any
---@return string
local function t(key, ...)
    local Config = require "configs.shared.main"
    local locale = Config.Locale or "en"
    if not locales[locale] then locale = "en" end
    local text = locales[locale][key] or key
    if select("#", ...) > 0 then
        return text:format(...)
    end
    return text
end

return { t = t }
