-- Test fixture: mixed server code — banking reference only.
-- luacheck: ignore 113
lib.callback.register("mixed-apartments:server:getBalance", function(source)
	local balance = exports["qb-banking"]:GetAccountBalance(source)
	return balance or 0
end)
