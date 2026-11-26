-- Test fixture: mixed client code — outfit handling only.
-- Built against ox_lib 3.37.2 (old pin, should be flagged).
-- luacheck: ignore 113 211
RegisterNetEvent("qb-clothing:client:loadOutfit", function(outfit)
	local ped = PlayerPedId()
	TriggerEvent("qb-clothing:client:loadOutfit", outfit)
	lib.notify({ title = "Outfit loaded", type = "success" })
end)
