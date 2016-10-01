local commands = {}
commands.global = {}

local json = require("dkjson")
local url = require("socket.url")
local copas = require("copas")
local util = require("lib/util")

local commandTimeout = 1 -- commands can run for a maximum of 1 second
local maxReply = 200

local lfs = require("lfs")

if _VERSION == "Lua 5.3" or _VERSION == "Lua 5.2" then
	function setfenv(f, env)
   		 return load(string.dump(f), nil, nil, env)
	end
end

local function sendChat(target, speaker, text)
	s:sendChat(target, speaker .. ", " .. text)
end

local function sandboxCommand(func)
	local luaenv = {
		print = print;
		startTime = startTime;
		table = {
			setn = table.setn;
			getn = table.getn;
			insert = table.insert;
			remove = table.remove;
			foreachi = table.foreachi;
			maxn = table.maxn;
			foreach = table.foreach;
			concat = table.concat;
			sort = table.sort;
			remove = table.remove;
		};
		string = {
			sub = string.sub;
			upper = string.upper;
			len = string.len;
			gfind = string.gfind;
			rep = string.rep;
			find = string.find;
			match = string.match;
			char = string.char;
			dump = string.dump;
			gmatch = string.gmatch;
			reverse = string.reverse;
			byte = string.byte;
			format = string.format;
			gsub = string.gsub;
			lower = string.lower;
		};
		math = {
			log = math.log;
			max = math.max;
			acos = math.acos;
			huge = math.huge;
			ldexp = math.ldexp;
			pi = math.pi;
			cos = math.cos;
			tanh = math.tanh;
			pow = math.pow;
			deg = math.deg;
			tan = math.tan;
			cosh = math.cosh;
			sinh = math.sinh;
			random = math.random;
			randomseed = math.randomseed;
			frexp = math.frexp;
			ceil = math.ceil;
			floor = math.floor;
			rad = math.rad;
			abs = math.abs;
			sqrt = math.sqrt;
			modf = math.modf;
			asin = math.asin;
			min = math.min;
			mod = math.mod;
			fmod = math.fmod;
			log10 = math.log10;
			atan2 = math.atan2;
			exp = math.exp;
			sin = math.sin;
			atan = math.atan;
		};
		_VERSION = _VERSION;
		coroutine = {
			resume = coroutine.resume;
			yield = coroutine.yield;
			status = coroutine.status;
			wrap = coroutine.wrap;
			create = coroutine.create;
			running = coroutine.running;
		};
		tostring = tostring;
		tonumber = tonumber;
		pcall = pcall;
		xpcall = xpcall;
		getmetatable = getmetatable;
		setmetatable = setmetatable;
		loadstring = loadstring;
		ipairs = ipairs;
		pairs = pairs;
		select = select;
		error = error;
		type = type;
		next = next;

		os = {
			date = os.date;
			time = os.time;
			difftime = os.difftime;
			clock = os.clock;
		};

		json = {
			encode = json.encode;
			decode = json.decode;
			quotestring = json.quotestring;
			addnewline = json.addnewline;
			encodeexception = json.encodeexception;
		};

		https = {
			get = httpsGet;
			post = httpsPost;
			request = copas.http.request;
		};

		http = {
			get = httpGet;
			post = httpPost;
			request = copas.http.request;
		};

		url = {
			escape = url.escape;
			unescape = url.unescape;
		};
	}
	luaenv._G = luaenv

	setmetatable(luaenv, {__newindex = function(self, index, val)
		if index ~= "_target" and index ~= "_speaker" then
			rawset(self, index, val)
		end
	end})

	luaenv.reply = function(text)
		text = tostring(text)
		if #text > maxReply then return end
		sendChat(luaenv._target, luaenv._speaker, text)
	end

	setfenv(func, luaenv)
end

function addCommand(name, callback, channel)
	channel  = channel or "global"
	if not channel then
		commands.global[name] = callback
	else
		if channel ~= "global" then
			sandboxCommand(callback)
		end
		if not commands[channel] then
			commands[channel] = {}
		end
		commands[channel][name] = callback
	end
end

function callCommand(name, usert, channel, args)
	local user = usert.username
	channel = channel or ".global"

	local func
	if commands[channel] and commands[channel][name] then
		func = commands[channel][name]
		local f = getfenv(func)
		rawset(f, "_speaker", name)
		rawset(f, "_target", channel)
	else
		func = commands.global[name]
	end

	if not func then
		return false, "command does not exist"
	end

	local succ, err = pcall(func, usert, channel, args)

	if not succ then
		return false, err
	end

	return true
end

function loadCommands()
	for name in lfs.dir("commands") do
		if name ~= "." and name ~= ".." then
			local count = 0
			local file = io.open("commands/" .. name, "r")
			if file then
				local tbl = util.unserialize(file:read("*a"))
				file:close()

				if tbl then
					for cmd, func in pairs(tbl) do
						local func, err = loadstring(func, cmd)
						if not func then
							log("Error loading command " .. cmd .. " for channel " .. name .. ": %{yellow}" .. err)
						else
							addCommand(cmd, func, name)
							count = count + 1
						end
					end
				end
			end

			log("Loaded %{cyan}" .. count .. "%{reset} command" .. (count ~= 1 and "s" or "") .. " for %{yellow}" .. name)
		end
	end
end

loadCommands()

require("modules/commands/global")
