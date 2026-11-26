-- Test fixture: a heavy QBCore resource. Expected severity: break.
-- luacheck: ignore 113
fx_version("cerulean")
game("gta5")
lua54("yes")

name("heavy-qb-jobs")
description("A legacy QBCore job resource.")
version("2.3.1")

dependency("qb-core")

shared_scripts({
	"@qb-core/import.lua",
	"config.lua",
})

server_scripts({
	"server/main.lua",
})
