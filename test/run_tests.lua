-- Fixture tests for qbx_scanner. Runs with plain Lua 5.4 — no FiveM server needed:
--   lua5.4 test/run_tests.lua
-- Run from the resource root (the directory containing fxmanifest.lua).
-- Exits 0 when all tests pass, 1 otherwise.

local QbxPatterns = dofile("server/patterns.lua")
local QbxReport = dofile("server/report.lua")

local passed = 0
local failed = 0

local function check(name, condition, detail)
	if condition then
		passed = passed + 1
		print("PASS: " .. name)
	else
		failed = failed + 1
		print("FAIL: " .. name .. (detail and (" — " .. detail) or ""))
	end
end

local function read_file(path)
	local handle = io.open(path, "r")
	if not handle then
		return nil
	end
	local content = handle:read("*a")
	handle:close()
	return content
end

-- Analyse every .lua file under a fixture directory (manifest + scripts).
local function scan_fixture(dir)
	local files = {
		"fxmanifest.lua",
		"server/main.lua",
		"client/main.lua",
		"server.lua",
		"client.lua",
	}
	local matches = {}
	for _, file in ipairs(files) do
		local content = read_file(dir .. "/" .. file)
		if content then
			for _, match in ipairs(QbxPatterns.analyze_content(content, file)) do
				matches[#matches + 1] = match
			end
		end
	end
	return matches
end

local function has_pattern(matches, pattern_id)
	for _, match in ipairs(matches) do
		if match.pattern == pattern_id then
			return true
		end
	end
	return false
end

local function count_severity(matches, severity)
	local count = 0
	for _, match in ipairs(matches) do
		if match.severity == severity then
			count = count + 1
		end
	end
	return count
end

-- ---------------------------------------------------------------- clean-ox
local clean = scan_fixture("test/fixtures/clean-ox")
check("clean-ox has zero matches", #clean == 0, "got " .. #clean)
check("clean-ox severity is ok", QbxPatterns.resource_severity(clean) == "ok", QbxPatterns.resource_severity(clean))

-- ---------------------------------------------------------------- heavy-qb
local heavy = scan_fixture("test/fixtures/heavy-qb")
check("heavy-qb severity is break", QbxPatterns.resource_severity(heavy) == "break")
check("heavy-qb has at least 8 matches", #heavy >= 8, "got " .. #heavy)
for _, pattern_id in ipairs({
	"qb-core-export",
	"qbcore-getcoreobject",
	"qbcore-functions",
	"qbcore-shared",
	"qbcore-server-event",
	"qb-inventory",
	"qb-menu",
	"progressbar",
	"qb-phone",
	"db-player-vehicles",
}) do
	check("heavy-qb flags " .. pattern_id, has_pattern(heavy, pattern_id))
end
check("heavy-qb matches carry file and line", heavy[1].file ~= nil and heavy[1].line ~= nil)
check("heavy-qb matches carry a fix hint", heavy[1].hint ~= nil and #heavy[1].hint > 10)

-- ---------------------------------------------------------------- mixed
local mixed = scan_fixture("test/fixtures/mixed")
check("mixed severity is maybe", QbxPatterns.resource_severity(mixed) == "maybe")
check("mixed has zero break matches", count_severity(mixed, "break") == 0)
check("mixed flags qb-clothing", has_pattern(mixed, "qb-clothing"))
check("mixed flags qb-banking", has_pattern(mixed, "qb-banking"))
check("mixed flags oxlib-old-pin", has_pattern(mixed, "oxlib-old-pin"))

-- ---------------------------------------------------------------- helpers
check("compare_versions: 3.37.2 < 3.39.0", QbxPatterns.compare_versions("3.37.2", "3.39.0") == -1)
check("compare_versions: 3.42.2 > 3.39.0", QbxPatterns.compare_versions("3.42.2", "3.39.0") == 1)
check("compare_versions: 3.39.0 == 3.39.0", QbxPatterns.compare_versions("3.39.0", "3.39.0") == 0)

local manifest = read_file("test/fixtures/heavy-qb/fxmanifest.lua")
local collected = QbxPatterns.collect_files(manifest)
local found_main = false
for _, path in ipairs(collected) do
	if path == "server/main.lua" then
		found_main = true
	end
end
check("collect_files finds server/main.lua in the manifest", found_main)
check("excluded resources contain qbx_core", QbxPatterns.EXCLUDED_RESOURCES["qbx_core"] == true)
check("excluded resources contain self", QbxPatterns.EXCLUDED_RESOURCES["qbx_scanner"] == true)

-- ---------------------------------------------------------------- report
local report = QbxReport.build({
	{ name = "clean-ox-shop", state = "started", severity = "ok", matches = {} },
	{ name = "heavy-qb-jobs", state = "started", severity = "break", matches = heavy },
	{ name = "mixed-apartments", state = "started", severity = "maybe", matches = mixed },
}, "2026-11-26T00:00:00Z")
check("report counts resources", report.resources_scanned == 3)
check("report summary break_count is 1", report.summary.break_count == 1)
check("report summary maybe_count is 1", report.summary.maybe_count == 1)
check("report summary ok_count is 1", report.summary.ok_count == 1)

local json = QbxReport.to_json(report)
check("report JSON contains the scanner name", json:find("qbx_scanner", 1, true) ~= nil)
check("report JSON contains heavy-qb-jobs", json:find("heavy-qb-jobs", 1, true) ~= nil)
check("report JSON contains break severity", json:find('"severity":"break"', 1, true) ~= nil)
check("report JSON is valid object syntax", json:sub(1, 1) == "{" and json:sub(-1) == "}")

local escaped = QbxReport.to_json({ note = 'say "hi"\nbye' })
check("JSON encoder escapes quotes and newlines", escaped:find('\\"hi\\"\\nbye', 1, true) ~= nil)

-- print_summary must run without error (output goes to stdout).
QbxReport.print_summary(report)
check("print_summary runs", true)

print(("--- %d passed, %d failed"):format(passed, failed))
if failed > 0 then
	os.exit(1)
end
