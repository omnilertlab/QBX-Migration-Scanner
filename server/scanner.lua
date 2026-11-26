-- QbxScanner: FiveM glue for the QBX Pre-Flight Breakage Scanner.
-- Runs server-side only. Event-driven: one delayed scan after start plus the
-- `qbxscan` console command. No loops, no polling — 0.00ms idle resmon.
-- The pure matching logic lives in server/patterns.lua; the report builder
-- in server/report.lua.

local last_report = nil

local function log_info(message)
	if lib and lib.print and lib.print.info then
		lib.print.info(message)
	else
		print("[qbx_scanner] " .. message)
	end
end

-- Read one file from a resource. Returns the content string or nil.
local function read_resource_file(resource_name, path)
	local content = LoadResourceFile(resource_name, path)
	if type(content) == "string" and content ~= "" then
		return content
	end
	return nil
end

-- Scan a single resource. Returns a result table
-- { name, state, severity, matches = { ... } }.
local function scan_resource(resource_name)
	local matches = {}
	local manifest = read_resource_file(resource_name, "fxmanifest.lua")
	if manifest then
		local manifest_matches = QbxPatterns.analyze_content(manifest, "fxmanifest.lua")
		for _, match in ipairs(manifest_matches) do
			matches[#matches + 1] = match
		end
		for _, path in ipairs(QbxPatterns.collect_files(manifest)) do
			if path ~= "fxmanifest.lua" then
				local content = read_resource_file(resource_name, path)
				if content then
					local file_matches = QbxPatterns.analyze_content(content, path)
					for _, match in ipairs(file_matches) do
						matches[#matches + 1] = match
					end
				end
			end
		end
	end
	return {
		name = resource_name,
		state = GetResourceState(resource_name),
		severity = QbxPatterns.resource_severity(matches),
		matches = matches,
	}
end

-- Scan every resource except the QBox / ox stack and this scanner itself
-- (their qb-* mentions are bridge/migration code, not breakage).
local function run_scan()
	local results = {}
	local total = GetNumResources()
	for index = 0, total - 1 do
		local name = GetResourceByFindIndex(index)
		if name and not QbxPatterns.EXCLUDED_RESOURCES[name] then
			results[#results + 1] = scan_resource(name)
		end
	end
	table.sort(results, function(a, b)
		if a.severity ~= b.severity then
			local rank = { ["break"] = 1, maybe = 2, ok = 3 }
			return rank[a.severity] < rank[b.severity]
		end
		return a.name < b.name
	end)
	local generated_at = os.date("!%Y-%m-%dT%H:%M:%SZ")
	last_report = QbxReport.build(results, generated_at)
	QbxReport.print_summary(last_report)
	local ok, err = pcall(QbxReport.save, last_report)
	if ok then
		log_info("Full report written to resources/qbx_scanner/report.json")
	else
		log_info("Could not write report.json: " .. tostring(err))
	end
	return last_report
end

-- Console command: `qbxscan` runs a fresh scan, `qbxscan report` re-prints
-- the last summary. Restricted to console / ace holders only.
RegisterCommand("qbxscan", function(source, args)
	if source ~= 0 then
		return
	end
	if args[1] == "report" then
		if last_report then
			QbxReport.print_summary(last_report)
		else
			log_info("No scan yet this session — run `qbxscan` first.")
		end
		return
	end
	log_info("Scanning " .. GetNumResources() .. " resources for QBCore -> QBox breakage...")
	run_scan()
end, true)

-- One delayed scan shortly after this resource starts, so the other
-- resources are already loaded. No repeating timer, no polling.
AddEventHandler("onResourceStart", function(resource_name)
	if resource_name == GetCurrentResourceName() then
		SetTimeout(5000, function()
			log_info("Running pre-flight scan (5s after start)...")
			run_scan()
		end)
	end
end)
