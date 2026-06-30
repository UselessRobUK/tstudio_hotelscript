fx_version "cerulean"
game "gta5"

lua54 "yes"

author "TSTUDIO"
description "Hotel Management Script"
version "1.0.0"

ui_page "html/index.html"

files {
    "html/index.html",
    "html/style.css",
    "html/app.js",
    "html/images/*.*",
    "html/fonts/*.*",
    "html/sounds/*.*",

    "client/*.lua",
    "bridge/*.lua",
    "configs/shared/*.lua",
    "shared/*.lua",
}

shared_scripts {
    "@ox_lib/init.lua",
}

client_scripts {
    "client/_index.lua",
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/schema.lua",
    "server/_index.lua",
}

escrow_ignore {
    "configs/**/*.lua",
    "shared/**/*.lua",
    "html/*.css",
    "html/*.js",
    "html/*.html",
}

dependencies {
    "oxmysql",
    "ox_lib",
}
