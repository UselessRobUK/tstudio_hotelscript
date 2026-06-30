fx_version "cerulean"
game "gta5"

lua54 "yes"

author "TSTUDIO"
description "Hotel Management Script"
version "1.0.0"

ui_page "web/dist/index.html"

files {
    "web/dist/**/*.*",

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
    "web/dist/**/*.*",
}

dependencies {
    "oxmysql",
    "ox_lib",
}
