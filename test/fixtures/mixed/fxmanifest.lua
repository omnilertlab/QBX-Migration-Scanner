-- Test fixture: a mixed resource — no hard breaks, but data-loss risks.
-- Expected severity: maybe.
-- luacheck: ignore 113
fx_version("cerulean")
game("gta5")
lua54("yes")

name("mixed-apartments")
description("Mixed resource with outfit and banking references.")
version("1.2.0")

dependency("ox_lib")

shared_script("@ox_lib/init.lua")

client_scripts({
	"client/main.lua",
})

server_scripts({
	"server/main.lua",
})
