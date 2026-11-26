fx_version("cerulean")
game("gta5")
lua54("yes")

name("qbx_scanner")
description("QBCore -> QBox Pre-Flight Breakage Scanner (Free Lite).")
version("1.0.0")
author("Game-Server Software Studio")

dependency("ox_lib")

shared_script("@ox_lib/init.lua")

server_scripts({
	"server/patterns.lua",
	"server/report.lua",
	"server/scanner.lua",
})
