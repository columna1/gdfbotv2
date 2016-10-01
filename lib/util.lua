local function escapeString(string)
	return string:gsub("\\", "\\\\"):gsub("\n", "\\\n"):gsub("\"", "\\\"")
end

local util = {}

function util.serialize(val, spaces)
	spaces = spaces or 0

	if type(val) == "table" then
		local txt = ""
		txt = "{"
		local zero = true
		for key, v in pairs(val) do
			zero = false
			txt = txt .. "\n" .. string.rep("\t", spaces + 1) .. "[" .. serialize(key, spaces + 2) .. "] = " .. serialize(v, spaces + 2) .. ";"
		end
		txt = txt .. (not zero and ("\n" .. string.rep("\t", math.max(0, spaces - 1))) or "") .. "}"
		return txt
	elseif type(val) == "string" then
		return "\"" .. escapeString(val) .. "\""
	elseif type(val) == "number" then
		return tostring(val)
	elseif type(val) == "boolean" then
		return tostring(val)
	else
		return "nil"
	end
end

function util.unserialize(string)
	local f = loadstring("return " .. string)
	if f then
		return f()
	end
end

function util.splitArgs(args)
	local tbl = {}
	for part in args:gmatch("[^ ]+") do
		table.insert(tbl, part)
	end

	return tbl
end

return util
