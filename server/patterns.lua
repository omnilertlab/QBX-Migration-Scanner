-- QbxPatterns: pure pattern-matching engine for the QBX Pre-Flight Scanner.
-- No FiveM natives in this file, so it can be unit-tested with plain Lua 5.4.
-- Each pattern: id, Lua pattern, severity ("break" | "maybe"), category, hint.
-- Severity meanings:
--   break: the resource WILL fail or lose data on QBox as written.
--   maybe: the resource touches data/behaviour that does not carry over cleanly;
--          verify it by hand before migrating.

QbxPatterns = {}
QbxPatterns.VERSION = "1.0.0"

QbxPatterns.PATTERNS = {
	{
		id = "qb-core-export",
		-- Long-bracket string ends at "%" so the closing "]" is appended:
		-- a long bracket whose content ends in "]" would merge with its terminator.
		pattern = [===[exports%[['"]qb%-core['"]%]===] .. "]",
		severity = "break",
		category = "core",
		hint = "Uses the qb-core export. QBox exposes qbx_core instead — rewrite to exports['qbx_core'] / "
			.. "qbx_core exports.",
	},
	{
		id = "qbcore-functions",
		pattern = "QBCore%.Functions",
		severity = "break",
		category = "core",
		hint = "QBCore.Functions calls must be replaced with qbx_core exports (e.g. GetPlayer, GetPlayerData).",
	},
	{
		id = "qbcore-shared",
		pattern = "QBCore%.Shared",
		severity = "break",
		category = "core",
		hint = "QBCore.Shared tables moved: jobs/vehicles to qbx_core shared data, items to ox_inventory item "
			.. "definitions.",
	},
	{
		id = "qbcore-getcoreobject",
		pattern = "GetCoreObject",
		severity = "break",
		category = "core",
		hint = "QBCore core-object pattern; use qbx_core exports instead of GetCoreObject().",
	},
	{
		id = "qbcore-server-event",
		pattern = "QBCore:Server:",
		severity = "break",
		category = "core",
		hint = "QBCore server events were renamed on QBox — see the migration tables at docs.qbox.re/migrating.",
	},
	{
		id = "qbcore-client-event",
		pattern = "qb%-core:server:",
		severity = "break",
		category = "core",
		hint = "qb-core server event name; QBox renamed these events — see docs.qbox.re/migrating.",
	},
	{
		id = "qb-inventory",
		pattern = "qb%-inventory",
		severity = "break",
		category = "inventory",
		hint = "qb-inventory has no QBox equivalent. Migrate items to ox_inventory — qbx_core 1.24.1+ ships "
			.. "convertqbinventory.",
	},
	{
		id = "qb-target",
		pattern = "qb%-target",
		severity = "break",
		category = "target",
		hint = "qb-target is replaced by ox_target (ox_target only answers older qtarget exports). Rewrite "
			.. "interactions with ox_target.",
	},
	{
		id = "qb-menu",
		pattern = "qb%-menu",
		severity = "break",
		category = "ui",
		hint = "qb-menu has no QBox export. Replace with ox_lib context menus (lib.registerContext) — the Full "
			.. "Toolkit ships a qb-menu -> ox_lib shim.",
	},
	{
		id = "qb-input",
		pattern = "qb%-input",
		severity = "break",
		category = "ui",
		hint = "qb-input has no QBox export. Replace with ox_lib input dialogs (lib.inputDialog) — the Full "
			.. "Toolkit ships a shim.",
	},
	{
		id = "progressbar",
		pattern = "progressbar",
		severity = "break",
		category = "ui",
		hint = "progressbar exports are gone on QBox. Replace with ox_lib lib.progressBar / lib.progressCircle.",
	},
	{
		id = "qb-phone",
		pattern = "qb%-phone",
		severity = "break",
		category = "phone",
		hint = "qb-phone is replaced by NPWD. Contacts, messages and photos do NOT carry over — the Full "
			.. "Toolkit Data Rescuer imports what it can.",
	},
	{
		id = "qb-houses",
		pattern = "qb%-houses",
		severity = "break",
		category = "housing",
		hint = "qb-houses has no import into qbx_properties. Houses and their stashes do NOT carry over — the "
			.. "Full Toolkit Data Rescuer.",
	},
	{
		id = "qb-apartments",
		pattern = "qb%-apartments",
		severity = "break",
		category = "housing",
		hint = "qb-apartments has no import into qbx_properties. Apartments and their stashes do NOT carry "
			.. "over — the Full Toolkit Data Rescuer.",
	},
	{
		id = "qb-clothing",
		pattern = "qb%-clothing",
		severity = "maybe",
		category = "outfits",
		hint = "Saved outfits do not carry over to QBox. Players will need to re-create outfits after migration.",
	},
	{
		id = "weapon-attachments",
		pattern = "weapon_attachments",
		severity = "maybe",
		category = "weapons",
		hint = "Weapon attachments do not carry over. Check qbx_weapons configuration after migration.",
	},
	{
		id = "qb-weapons",
		pattern = "qb%-weapons",
		severity = "maybe",
		category = "weapons",
		hint = "qb-weapons attachment data does not carry over. Verify weapon configs against qbx_weapons "
			.. "after migration.",
	},
	{
		id = "db-player-vehicles",
		pattern = "player_vehicles",
		severity = "break",
		category = "database",
		hint = "Direct access to the player_vehicles table bypasses the QBox bridge. Use qbx_core exports / "
			.. "oxmysql against the QBox schema.",
	},
	{
		id = "db-players-table",
		pattern = "FROM%s+players%f[^%w]",
		severity = "break",
		category = "database",
		hint = "Direct SQL against the players table bypasses the QBox bridge. Use qbx_core player exports instead.",
	},
	{
		id = "db-apartments-table",
		pattern = "FROM%s+apartments%f[^%w]",
		severity = "break",
		category = "database",
		hint = "Direct SQL against the apartments table. Apartments do not migrate to qbx_properties — see the "
			.. "Full Toolkit Data Rescuer.",
	},
	{
		id = "db-houses-table",
		pattern = "FROM%s+houses%f[^%w]",
		severity = "break",
		category = "database",
		hint = "Direct SQL against the houses table. Houses do not migrate to qbx_properties — see the Full "
			.. "Toolkit Data Rescuer.",
	},
	{
		id = "qb-garages",
		pattern = "qb%-garages",
		severity = "maybe",
		category = "garages",
		hint = "Garages: vehicle ownership migrates via the QBox player tables, but garage configs must be "
			.. "re-checked against qbx_garages.",
	},
	{
		id = "qb-banking",
		pattern = "qb%-banking",
		severity = "maybe",
		category = "banking",
		hint = "Bank transaction history does not carry over to QBox. Balances migrate; history does not.",
	},
	{
		id = "qb-management",
		pattern = "qb%-management",
		severity = "maybe",
		category = "jobs",
		hint = "qb-management is replaced by qbx_management. Reconfigure jobs, grades and boss menus after migration.",
	},
	{
		id = "qb-bossmenu",
		pattern = "qb%-bossmenu",
		severity = "maybe",
		category = "jobs",
		hint = "qb-bossmenu is replaced by qbx_management. Reconfigure jobs, grades and boss menus after migration.",
	},
	{
		id = "qbcore-mention",
		pattern = "qb%-core",
		severity = "maybe",
		category = "core",
		hint = "Mentions qb-core. Verify the resource does not depend on qb-core at runtime.",
	},
}

-- Resources that are part of the QBox / ox stack (or this scanner itself).
-- They legitimately mention qb-* identifiers (bridges, migration code) and
-- must not be flagged.
QbxPatterns.EXCLUDED_RESOURCES = {
	qbx_scanner = true,
	qbx_core = true,
	ox_lib = true,
	ox_inventory = true,
	ox_target = true,
	oxmysql = true,
	ox_doorlock = true,
}

-- Conventional entry-point files tried when a manifest uses globs
-- (e.g. server/*.lua) that cannot be expanded without a directory listing.
QbxPatterns.CONVENTIONAL_FILES = {
	"server.lua",
	"client.lua",
	"shared.lua",
	"config.lua",
	"server/main.lua",
	"client/main.lua",
	"server/server.lua",
	"client/client.lua",
}

local function trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Compare two "major.minor.patch" versions. Returns -1, 0 or 1.
local function compare_versions(a, b)
	local function parts(v)
		local major, minor, patch = v:match("^(%d+)%.(%d+)%.(%d+)")
		return tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0
	end
	local a1, a2, a3 = parts(a)
	local b1, b2, b3 = parts(b)
	if a1 ~= b1 then
		return a1 < b1 and -1 or 1
	end
	if a2 ~= b2 then
		return a2 < b2 and -1 or 1
	end
	if a3 ~= b3 then
		return a3 < b3 and -1 or 1
	end
	return 0
end

QbxPatterns.compare_versions = compare_versions

-- Check one line for an explicit ox_lib version pin below 3.39.0.
-- ox_lib 3.37.2 added prop validation that broke progress bars on
-- qbx_core 1.23.0; fixed only in ox_lib >= 3.39.0.
-- Returns a match table or nil.
local function check_oxlib_pin(line, line_number, filename)
	if not line:find("ox_lib") then
		return nil
	end
	local version = line:match("([23]%.%d+%.%d+)")
	if not version then
		return nil
	end
	if compare_versions(version, "3.39.0") < 0 then
		return {
			pattern = "oxlib-old-pin",
			file = filename,
			line = line_number,
			snippet = trim(line),
			severity = "maybe",
			category = "ox_lib",
			hint = "ox_lib "
				.. version
				.. " is pinned below 3.39.0. ox_lib 3.37.2 prop validation "
				.. "broke progress bars on qbx_core 1.23.0 — pin ox_lib >= 3.39.0.",
		}
	end
	return nil
end

QbxPatterns.check_oxlib_pin = check_oxlib_pin

-- Analyse one file's contents. Returns a list of match tables:
-- { pattern, file, line, snippet, severity, category, hint }.
-- Per line, a "maybe" match is dropped when the same line already has a
-- "break" match, so the report stays readable instead of double-flagging.
function QbxPatterns.analyze_content(content, filename)
	local matches = {}
	if type(content) ~= "string" or content == "" then
		return matches
	end
	local line_number = 0
	for line in (content .. "\n"):gmatch("(.-)\n") do
		line_number = line_number + 1
		local line_has_break = false
		for _, entry in ipairs(QbxPatterns.PATTERNS) do
			if line:find(entry.pattern) then
				if entry.severity == "break" then
					line_has_break = true
				end
				table.insert(matches, {
					pattern = entry.id,
					file = filename,
					line = line_number,
					snippet = trim(line),
					severity = entry.severity,
					category = entry.category,
					hint = entry.hint,
				})
			end
		end
		-- Drop "maybe" matches on a line that already has a "break" match.
		if line_has_break then
			local kept = {}
			for _, match in ipairs(matches) do
				if match.line ~= line_number or match.severity == "break" then
					table.insert(kept, match)
				end
			end
			matches = kept
		end
		local pin = check_oxlib_pin(line, line_number, filename)
		if pin then
			table.insert(matches, pin)
		end
	end
	return matches
end

-- Severity for a whole resource from its matches.
function QbxPatterns.resource_severity(matches)
	local has_maybe = false
	for _, match in ipairs(matches) do
		if match.severity == "break" then
			return "break"
		end
		if match.severity == "maybe" then
			has_maybe = true
		end
	end
	if has_maybe then
		return "maybe"
	end
	return "ok"
end

-- Collect candidate .lua file paths from a manifest's contents:
-- every quoted string ending in .lua, plus conventional entry points.
-- Globs (e.g. 'server/*.lua') cannot be expanded without a directory
-- listing, so the conventional paths cover the common layouts.
function QbxPatterns.collect_files(manifest_content)
	local found = {}
	local seen = {}
	local function add(path)
		if path and not seen[path] then
			seen[path] = true
			table.insert(found, path)
		end
	end
	if type(manifest_content) == "string" then
		for path in manifest_content:gmatch("'([^']+%.lua)'") do
			add(path)
		end
		for path in manifest_content:gmatch('"([^"]+%.lua)"') do
			add(path)
		end
	end
	for _, path in ipairs(QbxPatterns.CONVENTIONAL_FILES) do
		add(path)
	end
	return found
end

return QbxPatterns
