return {
    Debug = true,

    Locale = "en",

    InteractKey = 38,

    DefaultPayment = "cash",

    Currency = "£",

    UsePhysicalKeys = false,
    KeyItem = "hotel_key",

    StashSlots = 30,
    StashWeight = 50000,

    RoomDefaultDuration = 24,
    AutoExpireCheck = 60,

    AdminAces = {
        "hotel.admin",
        "admin",
    },

    AdminIdentifiers = {
        -- ["license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"] = true,
    },

    BossIdentifiers = {
        -- ["license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"] = true,
    },

    OptionalResources = {
        inventory = "auto",
        banking   = "standalone",
        target    = "auto",
        doorlock  = "auto",
        wardrobe  = "auto",
        phone     = "auto",
    },
}
