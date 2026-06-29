--========================================================--
-- Standalone Hotel Framework
-- shared/config.lua
--========================================================--

Config = Config or {}

Config.Debug = true

Config.Locale = "en"

Config.InteractKey = 38 -- E

Config.DefaultPayment = "cash" -- cash | bank

Config.Currency = "£"

Config.UsePhysicalKeys = false
Config.KeyItem = "hotel_key"

Config.StashSlots = 30
Config.StashWeight = 50000

Config.RoomDefaultDuration = 24 -- hours
Config.AutoExpireCheck = 60 -- seconds

Config.AdminAces = {
    "hotel.admin",
    "admin"
}

Config.AdminIdentifiers = {
    -- ["license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"] = true
}

Config.BossIdentifiers = {
    -- ["license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"] = true
}

Config.Webhooks = {
    default = "",
    rentals = "",
    bookings = "",
    complaints = "",
    staff = ""
}

Config.OptionalResources = {
    inventory = "auto",     -- auto | ox | qb | qs | standalone
    banking = "standalone", -- standalone | custom
    target = "auto",        -- auto | ox | qb | standalone
    doorlock = "auto",      -- auto | ox | standalone
    wardrobe = "auto",      -- auto | illenium | fivem | qb | esx | rcore | standalone
    phone = "auto"          -- auto | qb-phone | qs-smartphone | gksphone | lb-phone | standalone
}
