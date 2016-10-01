local wwwdir = "www"

local ssl = require("ssl")
local url = require("socket.url")
local lfs = require("lfs")
local json = require("dkjson")
local ltn12 = require("ltn12")
local sql = require("lsqlite3")
local copas = require("copas")
copas.http = require("copas.http")
local coxpcall = require("coxpcall")
local http = require("lib/http")
require("lib/statistics")
require("lib/permissions")

local httpsocket = socket.bind("*", 8080)
local httpssocket = socket.bind("*", 10443)

session = require("modules/http/sessions")

local clients = {}

local function sanitizePath(path)
	local parts = {}
	for part in path:gmatch("[^/\\]+") do
		if part ~= "." then
			if part == ".." then
				if #parts ~= 0 then
					table.remove(parts, #parts)
				end
			else
				table.insert(parts, part)
			end
		end
	end

	return table.concat(parts, "/")
end

function httpDestroyClient(client)
	client.conn:close()
	clients[client.conn] = nil
end

function httpBasicHeader(type, connection)
	return {
		{"Content-Type", type or "text/plain"};
		{"Connection", connection or "Close"};
	}
end

local mimetypes = {
	["html"] = "text/html";
	["css"] = "text/css";
	["ico"] = "image/x-icon";
	["js"] = "application/javascript";
	["woff"] = "application/font-woff";
	["woff2"] = "application/font-woff";
	["ttf"] = "application/octet-stream";
	["svg"] = "application/octet-stream";
	["eot"] = "application/octet-stream";
	["less"] = "text/css";
}

local handlers = {
	["GET"] = {};
	["POST"] = {};
}

function httpHandler(method, path, callback)
	if method ~= "GET" and method ~= "POST" then
		error("unsupported method: " .. method, 2)
	end

	path = sanitizePath(path)

	handlers[method][path] = callback
end

function removeHttpHandler(method, path)
	if method ~= "GET" and method ~= "POST" then
		error("unsupported method: " .. method, 2)
	end

	handlers[method][path] = nil
end

local function tryHandler(client, args)
	local c = handlers[client.method][args.path]
	if not c then
		return false
	end

	local succ, err = coxpcall.pcall(c, client, args)
	if not succ then
		log("error in " .. client.method .. " handler for " .. args.path .. ": " .. err)
	end

	return true
end

local function parseQuery(query)
	local args = {}
	for part in query:gmatch("[^%&]+") do
		local name, val = part:match("([^=]+)=?(.*)")
		args[url.unescape(name)] = val and url.unescape(val) or true
	end

	return args
end

local redirectPage = [[<!DOCTYPE html>
<html>
<head>
<title>Moved</title>
</head>
<body>
<h1>Moved</h1>
<p>This page has moved to <a href="$URL">$URL</a>.</p>
</body>
</html>]]

local function handleLuaFile(client, data, filename, args)
	local response = ""
	local mime = "text/html"

	local luaenv = {
		maincfg = maincfg;
		cookies = client.cookies;
		method = client.method;
		args = args;
		database = database;

		respond = function(text)
			response = response .. text
		end;

		setMime = function(m)
			mime = m
		end;

		print = function(...)
			local str = table.concat({...}, "   ")
			log(str)
		end;

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
		pcall = coxpcall.pcall;
		xpcall = coxpcall.xpcall;
		getmetatable = getmetatable;
		setmetatable = setmetatable;
		loadstring = loadstring;
		ipairs = ipairs;
		pairs = pairs;
		select = select;
		error = error;
		type = type;
		assert = assert;

		io = {
			lines = io.lines;
			write = io.write;
			close = io.close;
			flush = io.flush;
			-- open = io.open;
			open = function(filename, mode)
				return io.open(wwwdir .. "/" .. sanitizePath(filename), mode)
			end;
			-- output = io.output;
			type = io.type;
			read = io.read;
			-- stderr = io.stderr;
			-- stdin = io.stdin;
			-- input = io.input;
			-- stdout = io.stdout;
			-- popen = io.popen;
			-- tmpfile = io.tmpfile;
		};

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

		session = {
			generateId = session.generateId;
			check = session.check;
		};

		permissions = { -- channel defaults to .global
			--[[
			getUserWebChannels = getUserWebChannels; -- (user)

			groupHasPermission = groupHasPermission; -- (group, permission [, channel])
			addGroupPermission = addGroupPermission; -- (group, permission [, channel])
			removeGroupPermission = removeGroupPermission; -- (group, permission [, channel])
			addUserPermission = addUserPermission; -- (user, permission [, channel])
			removeUserPermission = removeUserPermission; -- (user, permission [, channel])
			userHasPermission = userHasPermission; -- (user, command [, channel])

			groupDoesInherit = groupDoesInherit; -- (group, inherit group [, channel])
			userIsInGroup = userIsInGroup; -- (user, group [, channel])
			userIsAdmin = userIsAdmin; -- (user [, channel])
			userIsMod = userIsMod; -- (user [, channel])
			addGroupInherit = addGroupInherit; -- (group, inherit group [, channel])
			removeGroupInherit = removeGroupInherit; -- (group, inherit group [, channel])

			addUserGroup = addUserGroup; -- (user, group [, channel])
			removeUserGroup = removeUserGroup; -- (user, group [, channel])

			addGroup = addGroup; -- (group [, channel [, commands [, web permissions [, inherits] ] ] ])
			removeGroup = removeGroup; -- (group [, channel])
			removeUser = removeUser; -- (user [, channel])
			]]
			
			removeGroup = permissions.removeGroup;
			getUserWebChannels = permissions.getUserWebChannels;
			removeUserGroup = permissions.removeUserGroup;
			userIsAdmin = permissions.userIsAdmin;
			userHasPermission = permissions.userHasPermission;
			removeUserPermission = permissions.removeUserPermission;
			removeGroupInherit = permissions.removeGroupInherit;
			groupDoesInherit = permissions.groupDoesInherit;
			addGroupInherit = permissions.addGroupInherit;
			addUserPermission = permissions.addUserPermission;
			userIsMod = permissions.userIsMod;
			addUserGroup = permissions.addUserGroup;
			removeUser = permissions.removeUser;
			groupHasPermission = permissions.groupHasPermission;
			userIsInGroup = permissions.userIsInGroup;
			addGroupPermission = permissions.addGroupPermission;
		};

		sql = {
			OK = sql.OK;
			DONE = sql.DONE;
			BUSY = sql.BUSY;
			ROW = sql.ROW;
			ERROR = sql.ERROR;
			MISUES = sql.MISUSE;

			assert = sqlAssert;
		};

		https = {
			get = http.get;
			post = http.post;
			request = copas.http.request;
		};

		http = {
			get = http.get;
			post = http.post;
			request = copas.http.request;
		};

		url = {
			escape = url.escape;
			unescape = url.unescape;
		};

		statistics = {
			getLast = statistics.getLast;
		};
	}
	luaenv._G = luaenv

	local redirect
	luaenv.redirect = function(url)
		redirect = url
	end

	local setCookies = {}
	function luaenv.setCookie(name, value, expires)
		if expires then
			value = value .. "; expires=" .. expires
		end
		table.insert(setCookies, {name, value})
	end

	while true do
		response = ""
		local pos1, src, pos2 = data:match("()<%?lua(.-)%?>()")
		if not pos1 or not src or not pos2 then
			break
		else
			local func, err = loadstring(src, filename)
			if not func then
				log("error handling lua file: %{red}" .. err)
				client:respond("Internal server error", httpBasicHeader("text/plain"), 500)
				return
			end

			setfenv(func, luaenv)

			local success, err = coxpcall.pcall(func)
			if not success then
				log("error handling lua file: %{red}" .. err)
				client:respond("Internal server error", httpBasicHeader("text/plain"), 500)
				return
			end

			data = data:sub(0, pos1 - 1) .. response .. data:sub(pos2)
		end
	end

	local header = httpBasicHeader(mime)
	for _, cookie in ipairs(setCookies) do
		table.insert(header, {"Set-Cookie", cookie[1] .. "=" .. cookie[2]})
	end

	if redirect then
		local page = redirectPage:gsub("$URL", redirect)

		table.insert(header, {"Location", redirect})
		table.insert(header, {"Content-Type", "text/html"})
		table.insert(header, {"Content-Length", page:len()})

		client:respond(page, header, 302)
		return
	end

	client:respond(data, header, 200)
end

local function trimSpace(string)
	return string:match("^%s*(.-)%s*$")
end

local function onClientReceive(client)
	if not client.header then
		local request = client.conn:receive("*l")
		if not request then
			-- log("invalid http request: %{yellow}nil%{reset}, not disconnecting")
			httpDestroyClient(client)
			return
		end

		client.header = {}
		client.cookies = {}

		local method, uri, version = request:match("([^ ]+) ([^ ]+) (.+)")
		if not method or not uri or not version then
			log("invalid http request: %{yellow}" .. request .. "%{reset}, disconnecting")
			httpDestroyClient(client)
			return
		end

		client.method = method
		client.uri = uri
		client.version = version

		if method ~= "GET" and method ~= "POST" then
			log("unsupported method: %{yellow}" .. method .. "%{reset}, disconnecting")
			httpDestroyClient(client)
			return
		end

		local line, err
		repeat
			line, err = client.conn:receive("*l")
			if not line then
				log("%{red}client receive error: " .. err .. ", disconnecting")
				httpDestroyClient(client)
				return
			end

			if line ~= "" then
				local name, value = line:match("([^:]+):[ ]*(.+)")
				if not name or not value then
					log("%{red}invalid header entry: " .. line .. ", disconnecting")
					httpDestroyClient(client)
					return
				end

				name = name:lower()
				if name == "cookie" then
					for cookie in value:gmatch("[^;]+") do
						local name, value = cookie:match("(.-)=(.+)")
						if name and value then
							name = trimSpace(name)
							value = trimSpace(value)
							client.cookies[name] = value
						end
					end
				end

				client.header[name] = value
			end
		until line == ""
	end

	if not client.body then
		client.body = ""
	end

	if client.header["content-length"] then
		local data, err = client.conn:receive(tonumber(client.header["content-length"]) or error("invalid content-length"))
		if data then
			client.body = data
		end
	end

	local parsed = url.parse(client.uri)
	-- local path, args = client.uri:match("([^%?]+)%??(.*)")
	path = sanitizePath(parsed.path or "index.html")

	if lfs.attributes(wwwdir .. "/" .. path, "mode") == "directory" then
		path = path .. "/index.html"
	end

	if parsed.query then
		parsed.args = parseQuery(parsed.query)
	else
		parsed.args = {}
	end
	parsed.path = path

	if client.method == "GET" then
		log("[%{cyan}" .. tostring(client.address) .. "%{reset}:%{cyan}" .. tostring(client.port) .. "%{reset}] %{yellow}GET %{reset}" .. client.uri)

		local file, err = io.open(wwwdir .. "/" .. path, "rb")

		local ftype = (path:match("%.([^%.]+)$") or "html"):lower()

		local mime = mimetypes[ftype] or "text/plain"

		if not file then
			if not tryHandler(client, parsed) then
				client:respond("<!DOCTYPE html> <html><head><title>File not found</title></head><body><h1>File not found</h2></body></html>", httpBasicHeader("text/html", "Close"), 404)
				httpDestroyClient(client)
			end
			return
		else
			local data = file:read("*a")
			file:close()
			if not data then
				client:respond("<!DOCTYPE html> <html><head><title>File not found</title></head><body><h1>File not found</h2></body></html>", httpBasicHeader("text/html", "Close"), 404)
				httpDestroyClient(client)
				return
			end
			if ftype == "lua" then
				handleLuaFile(client, data, path, parsed)
			else
				client:respond(data, httpBasicHeader(mime, "Close"), 200)
			end
			httpDestroyClient(client)
			return
		end
	elseif client.method == "POST" then
		log("[%{cyan}" .. address .. "%{reset}:%{cyan}" .. port .. "%{reset}] %{yellow}POST %{reset}" .. client.uri)
		tryHandler(client, parsed)
	end

	httpDestroyClient(client)
end

local responseCodes = {
	[200] = "OK";
	[302] = "Moved Temporarily";
	[404] = "Not Found";
	[500] = "Internal Server Error";
}

local client_meta = {
	__index = {
		respond = function(self, data, headers, code)
			code = code or 200
			headers = headers or {}

			local response = "HTTP/1.1 " .. code .. " " .. (responseCodes[code] or "OK") .. "\r\n"
			repsonse = response .. "Content-Length: " .. #data .. "\r\n"
			for _, h in pairs(headers) do
				response = response .. h[1] .. ": " .. h[2] .. "\r\n"
			end

			response = response .. "\r\n" .. data

			self.conn:settimeout(nil)
			self.conn:send(response)
			self.conn:settimeout(0)
		end
	}
}

local function onConnection(conn, sec)
	local address, port = conn:getpeername()
	if sec then
		conn = copas.wrap(conn, {mode = "server", protocol = "tlsv1_2", key = "server.key", certificate = "server.crt"}):dohandshake()
	else
		conn = copas.wrap(conn)
	end

	local client = {conn = conn, rconn = rconn, address = address, port = port}
	setmetatable(client, client_meta)
	clients[conn] = client

	local succ, err = coxpcall.pcall(onClientReceive, client)
	if not succ then
		log("%{red}error in client handler: " .. tostring(err))
	end
end

local address, port = httpsocket:getsockname()
log("Hosting http server on %{cyan}" .. address .. "%{reset}:%{cyan}" .. port)
address, port = httpssocket:getsockname()
log("Hosting https server on %{cyan}" .. address .. "%{reset}:%{cyan}" .. port)

copas.addserver(httpsocket, onConnection)
copas.addserver(httpssocket, function(conn) onConnection(conn, true) end)
