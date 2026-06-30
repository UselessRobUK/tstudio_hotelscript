return {
    Debug = true,

    Locale = "en",

    InteractKey = 38,

    DefaultPayment = "cash",
    UseTarget = true,
    Currency = "£",

    UsePhysicalKeys = false,
    KeyItem = "hotel_key",
    CashItem = "money",

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
        ['license:f27362a27435e8ac090e81d4e2879382aed838b9'] = true, -- peak
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
