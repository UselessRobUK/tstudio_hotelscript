fx_version 'cerulean'
game 'gta5'

author 'Rob'
description 'Standalone Modular Hotel Framework'
version '1.0.0'

lua54 'yes'

shared_scripts {
    'config.lua',
    'shared/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}
