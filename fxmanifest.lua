--========================================================--
-- Ultimate Hotel Framework
-- fxmanifest.lua
--========================================================--

fx_version "cerulean"
game "gta5"

lua54 "yes"

author "TSTUDIO"
description "Hotel Management Script"
version "1.0.0"

----------------------------------------------------------
-- UI
----------------------------------------------------------

ui_page "html/index.html"

files {

    "html/index.html",
    "html/style.css",
    "html/app.js",

    "html/images/*.*",
    "html/fonts/*.*",
    "html/sounds/*.*"

}

----------------------------------------------------------
-- Shared
----------------------------------------------------------

shared_scripts {

    "@ox_lib/init.lua",

    "shared/config.lua",
    "shared/functions.lua",
    "shared/locale.lua",
    "shared/hotels.lua",
    "shared/rooms.lua"

}

----------------------------------------------------------
-- Client
----------------------------------------------------------

client_scripts {

    "client/utils.lua",
    "client/debug.lua",

    "client/notifications.lua",

    "client/ui.lua",

    "client/animations.lua",

    "client/booking.lua",

    "client/complaints.lua",

    "client/cleaning.lua",

    "client/elevators.lua",

    "client/instances.lua",

    "client/keys.lua",

    "client/npc.lua",

    "client/phone.lua",

    "client/rooms.lua",

    "client/stash.lua",

    "client/target.lua",

    "client/wardrobe.lua",

    "client/boss.lua",

    "client/builder.lua",

    "client/zones.lua"

}

----------------------------------------------------------
-- Server
----------------------------------------------------------

server_scripts {

    "@oxmysql/lib/MySQL.lua",

    "bridge/banking.lua",
    "bridge/doorlock.lua",
    "bridge/inventory.lua",
    "bridge/notifications.lua",
    "bridge/phone.lua",
    "bridge/stash.lua",
    "bridge/target.lua",
    "bridge/wardrobe.lua",

    "server/utils.lua",

    "server/main.lua",

    "server/callbacks.lua",

    "server/payments.lua",

    "server/banking.lua",

    "server/registry.lua",

    "server/rentals.lua",

    "server/bookings.lua",

    "server/rooms.lua",

    "server/keys.lua",

    "server/ownership.lua",

    "server/jobs.lua",

    "server/employees.lua",

    "server/boss.lua",

    "server/complaints.lua",

    "server/cleaning.lua",

    "server/inventory.lua",

    "server/stash.lua",

    "server/wardrobe.lua",

    "server/elevators.lua",

    "server/instances.lua",

    "server/phone.lua",

    "server/notifications.lua",

    "server/security.lua",

    "server/analytics.lua",

    "server/webhooks.lua",

    "server/persistence.lua",

    "server/config_loader.lua",

    "server/builder.lua",

    "server/exports.lua"

}

----------------------------------------------------------
-- Escrow
----------------------------------------------------------

escrow_ignore {

    "config.lua",

    "shared/*.lua",

    "html/*.css",

    "html/*.js",

    "html/*.html"

}

----------------------------------------------------------
-- Dependencies
----------------------------------------------------------

dependencies {

    "oxmysql"

}
