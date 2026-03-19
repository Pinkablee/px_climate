fx_version 'cerulean'
game 'gta5'

name 'px_climate'
version '0.1.0'
description 'Lightweight real-time weather and time sync for FiveM.'

client_script 'client/main.lua'

server_scripts {
    'server/main.lua',
    'server/version.lua'
}

shared_scripts {
    '@ox_lib/init.lua'
}

files {
    'config/shared.lua'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'