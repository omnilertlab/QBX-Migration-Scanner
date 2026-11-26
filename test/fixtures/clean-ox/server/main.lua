-- Test fixture: clean QBox-native server code. Expected: no matches.
-- luacheck: ignore 113
local ox_inventory = exports.ox_inventory

lib.callback.register("clean-ox-shop:server:getStock", function(source, item)
	local count = ox_inventory:Search(source, "count", item)
	return count or 0
end)

lib.callback.register("clean-ox-shop:server:buyItem", function(source, item, price)
	local player = exports.qbx_core:GetPlayer(source)
	if not player then
		return false
	end
	if player.Functions.RemoveMoney("cash", price) then
		ox_inventory:AddItem(source, item, 1)
		return true
	end
	return false
end)
