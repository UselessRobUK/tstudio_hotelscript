return {
    {
        id   = "pinkcage",
        name = "Pink Cage Motel",

        priceMultiplier = 1.0,

        entrance = vector3(307.25, -213.84, 54.22),

        reception = {
            model  = "s_m_m_highsec_01",
            coords = vector4(306.81, -214.53, 54.22, 159.0),
        },

        boss = vector3(304.80, -216.42, 54.22),

        elevators = {
            {
                id     = "main",
                coords = vector3(311.43, -217.19, 54.22),
                floors = {
                    {
                        label  = "Reception",
                        coords = vector4(311.43, -217.19, 54.22, 160.0),
                    },
                    {
                        label  = "Roof",
                        coords = vector4(329.84, -199.81, 71.03, 70.0),
                    },
                },
            },
        },

        rooms = {
            {
                id       = 101,
                label    = "Room 101",
                price    = 250,
                duration = 24,

                entrance = {
                    coords = vector4(312.21, -218.84, 54.22, 160.0),
                },

                inside   = vector4(151.43, -1007.63, -99.0, 356.0),
                outside  = vector4(312.21, -218.84, 54.22, 160.0),

                exit     = vector3(151.35, -1007.50, -99.0),
                stash    = vector3(154.08, -1001.96, -99.0),
                wardrobe = vector3(151.02, -1003.73, -99.0),

                door = {
                    id      = "pink101",
                    coords  = vector3(312.21, -218.84, 54.22),
                    heading = 160.0,
                },
            },
        },
    },
}
