-- Test fixture: heavy QBCore server code. Expected: many break matches.
-- luacheck: ignore 113 211
local QBCore = exports["qb-core"]:GetCoreObject()

RegisterNetEvent("QBCore:Server:OnMoneyChange", function()
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if not Player then
		return
	end
	local items = QBCore.Shared.Items
	local vehicle = exports["qb-inventory"]:GetItemByName(src, "vehicle_keys")
	exports["qb-menu"]:openMenu({
		{ header = "Job Menu", txt = "Open the job menu" },
	})
	exports["progressbar"]:Progress({
		name = "job_task",
		duration = 5000,
		label = "Working...",
	})
	local result =
		MySQL.query.await("SELECT * FROM player_vehicles WHERE citizenid = ?", { Player.PlayerData.citizenid })
	exports["qb-phone"]:SendNotification(src, "Job done")
end)
