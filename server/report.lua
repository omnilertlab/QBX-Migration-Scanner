-- QbxReport: builds the structured scan report, prints the console summary
-- and writes report.json. Pure Lua except for save(), which uses the
-- FiveM native SaveResourceFile — everything else is testable standalone.

QbxReport = {}
QbxReport.VERSION = "1.0.0"

local function json_escape(str)
	return (
		str:gsub('[%z\1-\31"\\]', function(c)
			if c == '"' then
				return '\\"'
			end
			if c == "\\" then
				return "\\\\"
			end
			if c == "\n" then
				return "\\n"
			end
			if c == "\r" then
				return "\\r"
			end
			if c == "\t" then
				return "\\t"
			end
			return ("\\u%04x"):format(c:byte())
		end)
	)
end

local function is_array(value)
	local count = 0
	for key, _ in pairs(value) do
		count = count + 1
		if type(key) ~= "number" or key < 1 or math.floor(key) ~= key then
			return false
		end
	end
	return count == #value
end

-- Minimal deterministic JSON encoder: object keys are sorted so report.json
-- is stable between runs. Handles strings, numbers, booleans, nil and tables.
local function encode(value, depth)
	depth = depth or 0
	local kind = type(value)
	if kind == "nil" then
		return "null"
	elseif kind == "boolean" then
		return value and "true" or "false"
	elseif kind == "number" then
		if value ~= value or value == math.huge or value == -math.huge then
			return "null"
		end
		return tostring(value)
	elseif kind == "string" then
		return '"' .. json_escape(value) .. '"'
	elseif kind == "table" then
		if is_array(value) then
			local parts = {}
			for i = 1, #value do
				parts[i] = encode(value[i], depth + 1)
			end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		local keys = {}
		for key, _ in pairs(value) do
			keys[#keys + 1] = key
		end
		table.sort(keys, function(a, b)
			return tostring(a) < tostring(b)
		end)
		local parts = {}
		for i, key in ipairs(keys) do
			parts[i] = '"' .. json_escape(tostring(key)) .. '":' .. encode(value[key], depth + 1)
		end
		return "{" .. table.concat(parts, ",") .. "}"
	else
		return "null"
	end
end

QbxReport.to_json = encode

-- Build the report table from per-resource results.
-- results: array of { name, state, severity, matches = { ... } }
function QbxReport.build(results, generated_at)
	local summary = { break_count = 0, maybe_count = 0, ok_count = 0 }
	local resources = {}
	for _, result in ipairs(results) do
		summary[result.severity .. "_count"] = (summary[result.severity .. "_count"] or 0) + 1
		resources[#resources + 1] = {
			name = result.name,
			state = result.state,
			severity = result.severity,
			issue_count = #result.matches,
			matches = result.matches,
		}
	end
	return {
		scanner = "qbx_scanner",
		scanner_version = QbxReport.VERSION,
		generated_at = generated_at or "unknown",
		resources_scanned = #results,
		summary = summary,
		resources = resources,
	}
end

-- Compact console summary. Uses plain print() so it works in the test harness.
function QbxReport.print_summary(report)
	local summary = report.summary
	print(
		("[qbx_scanner] Scan complete: %d resources — %d BREAK, %d MAYBE, %d OK"):format(
			report.resources_scanned,
			summary.break_count,
			summary.maybe_count,
			summary.ok_count
		)
	)
	for _, resource in ipairs(report.resources) do
		if resource.severity ~= "ok" then
			print(
				("[qbx_scanner] %s: %s (%d issue%s)"):format(
					string.upper(resource.severity),
					resource.name,
					resource.issue_count,
					resource.issue_count == 1 and "" or "s"
				)
			)
			local shown = 0
			for _, match in ipairs(resource.matches) do
				shown = shown + 1
				if shown <= 5 then
					print(("  %s:%d [%s] %s"):format(match.file, match.line, match.pattern, match.hint))
				end
			end
			if resource.issue_count > 5 then
				print(("  ... and %d more — see report.json"):format(resource.issue_count - 5))
			end
		end
	end
	print("[qbx_scanner] Full report: resources/qbx_scanner/report.json (or run: qbxscan report)")
	print("[qbx_scanner] Fix the BREAK items with the Full Migration Toolkit — converter, shims and data rescuers.")
end

-- Write report.json into this resource folder (FiveM only).
-- Returns true on success.
function QbxReport.save(report)
	local json = encode(report)
	SaveResourceFile(GetCurrentResourceName(), "report.json", json, -1)
	return true
end

return QbxReport
