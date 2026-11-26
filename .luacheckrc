-- luacheck configuration for qbx_scanner.
std = "lua54"
unused = true
redefined = false
-- FiveM server natives used by this resource.
read_globals = {
	"GetNumResources",
	"GetResourceByFindIndex",
	"GetResourceState",
	"GetCurrentResourceName",
	"LoadResourceFile",
	"SaveResourceFile",
	"RegisterCommand",
	"AddEventHandler",
	"SetTimeout",
	-- ox_lib (loaded via @ox_lib/init.lua).
	"lib",
}
-- Globals shared between this resource's server scripts.
globals = {
	"QbxPatterns",
	"QbxReport",
}
-- fxmanifest.lua is a DSL: its calls are FiveM manifest functions, not Lua globals.
files["fxmanifest.lua"] = {
	read_globals = {
		"fx_version",
		"game",
		"lua54",
		"name",
		"description",
		"version",
		"author",
		"dependency",
		"shared_script",
		"shared_scripts",
		"server_script",
		"server_scripts",
		"client_script",
		"client_scripts",
		"files",
		"ui_page",
	},
}
