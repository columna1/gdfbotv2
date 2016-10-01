local io = require("io")

local config = {}

config.read = function(path)
	local file = io.open(path, "r")
	if file then
		local cfg = {}
		for line in file:lines() do
			if line ~= "" then
				local name, val = line:match("%s*([^:%s]+)%s*:%s*(.-)%s*$")
				if not name or not val then
					print("Invalid line in " .. path .. ": " .. line)
				else
					cfg[name] = val
				end
			end
		end
		file:close()
		return cfg
	end
end

config.write = function(path, config)
	local file, err = io.open(path, "w")
	if not file then
		print("Could not write config " .. path .. ": " .. err)
		return false
	end
	
	for i,v in pairs(config) do
		if i:find(" ") then
			file:close()
			error("configuration name " .. i .. " has spaces; aborting", 2)
		else
			file:write(i .. ": " .. v .. "\n")
		end
	end
	file:close()
	return true
end

return config
