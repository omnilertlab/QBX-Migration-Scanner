-- Test fixture: a clean, QBox-native resource. Expected severity: ok.
-- luacheck: ignore 113
fx_version("cerulean")
game("gta5")
lua54("yes")

name("clean-ox-shop")
description("A clean QBox-native shop using ox_inventory and ox_lib.")
version("1.0.0")

dependency("ox_lib")

shared_script("@ox_lib/init.lua")

server_scripts({
	"server/main.lua",
})
