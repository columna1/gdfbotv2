--version that allows you to pick the user
local copas = require("copas")
-- local json = require("json")
local socket = require("socket")
local ssl = require("ssl")
print = print
function send(...)
	print(...)
end
function printTable(tabl, wid)
	for i,v in pairs(tabl) do
		if type(v) == "table" then
			print(string.rep(" ", wid * 3) .. i .. " = {")
			printTable(v, wid + 1)
			print(string.rep(" ", wid * 3) .. "}")
		elseif type(v) == "string" then
			print(string.rep(" ", wid * 3) .. i .. " = \"" .. v .. "\"")
		elseif type(v) == "number" then
			print(string.rep(" ", wid * 3) .. i .. " = " .. v)
		end
	end
end

local error = error
local setmetatable = setmetatable
local rawget = rawget
local unpack = unpack
local pairs = pairs
local assert = assert
local require = require
local tonumber = tonumber
local type = type
local pcall = pcall
local socket = require("socket")
local print = print
local sub = string.sub
local byte = string.byte
local char = string.char
local table = table
local tostring = tostring
local random = math.random
local find = string.find
local select = select

module("irc")
local meta = {}
meta.__index = meta
_META = meta
local meta_preconnect = {}
function meta_preconnect.__index(o, k)
	local v = rawget(meta_preconnect, k)

	if not v and meta[k] then
		error(("field '%s' is not accessible before connecting"):format(k), 2)
	end
	return v
end

function checkNick(nick)
	return find(nick,"^[a-zA-Z_%-%[|%]%^{|}`][a-zA-Z0-9_%-%[|%]%^{|}`]*$") ~= nil
end

function new(nick)
	local tab = {}
	tab.track_users = true
	if not nick then error("no nickname") else tab.nickname = nick.nick end
	if not nick.username then tab.username = "Lua" else tab.username = nick.username end
	if not nick.realname then tab.realname = "Lua Irc Bot" else tab.realname = nick.realname end
	assert(checkNick(tab.nickname), "bad nickname passed to irc.new")
	return setmetatable(tab, meta_preconnect)
end

function meta_preconnect:connect(_host,_port, _ssl)
	local host, port, password, secure, timeout

	if type(_host) == "table" then
		host = _host.host
		port = _host.port
		timeout = _host.timeout
		password = _host.password
		secure = _host.secure
	else
		host = _host
		port = _port
	end

	host = host or error("host name required to connect", 2)
	port = port or 6667

	local s = socket.tcp()

	local sslparams
	if _ssl then
		sslparams = {
			mode = "client",
			protocol = "sslv23"
		}
	end

	s = copas.wrap(s, sslparams)
	assert(s:connect(host, port))

	self.socket = s
	setmetatable(self, meta)

	if password then
		self:send("PASS %s",password)
	end
	self:send("NICK %s",self.nickname)
	self:send("USER %s 0 * :%s", self.username, self.realname)

	self.channels = {}
	self.pinged = true

	repeat
		self:think()
	until self.authed
end

local function getline(self, errlevel)
	local line, err = self.socket:receive("*l")

	if not line and err ~= "timeout" and err ~= "wantread" then
		self:invoke("OnDisconnect", err, true)
		self:shutdown()
		error(err, errlevel)
	end

	--if line ~= nil then print(line) end

	return line
end

function meta:think()
	--get the line of text, split it up, and then deal with the command accordingly
	local line = getline(self, 3)
	if line and #line > 0 then
		if not self:invoke("OnRaw", line) then
			self:handle(parse(line))
		end
	end
end

function meta:handle(prefix, cmd, params)
	local handler = handlers[cmd]
	if handler then
		return handler(self, prefix, unpack(params))
	end
end


function meta:hook(name, id, f)
	f = f or id
	if not self.hooks then self.hooks = {} end
	--self.hooks[name] = self.hooks[name] or {}
	self.hooks[name] = {}
	-- print(id)
	self.hooks[name][id] = f
	return id or f
end
meta_preconnect.hook = meta.hook


function meta:unhook(name, id)
	local hooks = self.hooks[name]

	assert(hooks, "no hooks exist for this event")
	assert(hooks[id], "hook ID not found")

	hooks[id] = nil
end
meta_preconnect.unhook = meta.unhook

function meta:invoke(name, ...)
	if not self.hooks then
		return
	end
	local hooks = self.hooks[name]
	if hooks then
		for id,f in pairs(hooks) do
			if f(...) then
				return true
			end
		end
	end
end

function parse(line)
	local prefix
	local lineStart = 1
	if line:sub(1,1) == ":" then
		local space = line:find(" ")
		prefix = line:sub(2, space-1)
		lineStart = space
	end

	local _, trailToken = line:find("%s+:", lineStart)
	local lineStop = line:len()
	local trailing
	if trailToken then
		trailing = line:sub(trailToken + 1)
		lineStop = trailToken - 2
	end

	local params = {}

	local _, cmdEnd, cmd = line:find("(%S+)", lineStart)
	local pos = cmdEnd + 1
	while true do
		local _, stop, param = line:find("(%S+)", pos)

		if not param or stop > lineStop then
			break
		end

		pos = stop + 1
		params[#params + 1] = param
	end

	if trailing then
		params[#params + 1] = trailing
	end

	return prefix, cmd, params
end

function parsePrefix(prefix)
	local user = {}
	if prefix then
		user.access, user.nick, user.username, user.host = prefix:match("^([%+@]*)(.+)!(.+)@(.+)$")
	end
	--user.access = parseAccess(user.access or "")
	return user
end

function meta:send(msg, ...)
	--print("here")
	--print(select("#", ...))
	--for i,k in pairs(...) do
	--	print(i,k)
	--end
	if ... and select("#", ...) > 0 then
		msg = msg:format(...)
	end
	self:invoke("OnSend", msg)
	if #msg > 512 then msg = sub(msg,0,500).."..." end
	local bytes, err = self.socket:send(msg .. "\r\n")

	if not bytes and err ~= "timeout" and err ~= "wantwrite" then
		self:invoke("OnDisconnect", err, true)
		self:shutdown()
		error(err, errlevel)
	end
end

local function verify(str, errLevel)
	if str:find("^:") or str:find("%s%z") then
		error(("malformed parameter '%s' to irc command"):format(str), errLevel)
	end

	return str
end

function meta:sendChat(target, msg)
	-- Split the message into segments if it includes newlines.
	for line in msg:gmatch("([^\r\n]+)") do
		self:send("PRIVMSG %s :%s", verify(target, 3), line)
	end
end

function meta:join(channel, key)
	if key then
		self:send("JOIN %s :%s", verify(channel, 3), verify(key, 3))
	else
		self:send("JOIN %s", verify(channel, 3))
	end
end

function meta:part(channel)
	channel = verify(channel, 3)
	self:send("PART %s", channel)
	if self.track_users then
		self.channels[channel] = nil
	end
end

function meta:disconnect(message)
	message = message or "Bye!"

	self:invoke("OnDisconnect", message, false)
	self:send("QUIT :%s", message)

	self:shutdown()
end


function meta:shutdown()
	self.socket:close()
	setmetatable(self, nil)
end

local whoisHandlers = {
	["311"] = "userinfo";
	["312"] = "node";
	["319"] = "channels";
	["330"] = "account"; -- Freenode
	["307"] = "registered"; -- Unreal
}

function meta:whois(nick)
	self:send("WHOIS %s", nick)

	local result = {}

	while true do
		local line = getline(self, 3)
		if line then
			local prefix, cmd, args = parse(line)

			local handler = whoisHandlers[cmd]
			if handler then
				result[handler] = args
			elseif cmd == "318" then
				break
			else
				self:handle(prefix, cmd, args)
			end
		end
	end

	if result.account then
		result.account = result.account[3]
	elseif result.registered then
		result.account = result.registered[2]
	end

	return result
end

function meta:topic(channel)
	self:send("TOPIC %s", channel)
end

function parseNick(nick)
	local access, name = nick:match("^([%+@]*)(.+)$")
	return  parseAccess(access or "") , name
end

function parsePrefix(prefix)
	local user = {}
	if prefix then
		user.access, user.nick, user.username, user.host = prefix:match("^([%+@]*)(.+)!(.+)@(.+)$")
	end
	user.access = parseAccess(user.access or "")
	return user
end

function parseAccess(accessString)

	local access = {op = false, halfop = false, voice = false, owner = false}
	for c in accessString:gmatch(".") do
		if     c == "@" then access.op      = true
		elseif c == "%" then access.halfop  = true
		elseif c == "~" then access.owner   = true
		elseif c == "+" then access.voice   = true
		end
	end
	return access
end

function meta:trackUsers(b)
	self.track_users = b
	if not b then
		for k,v in pairs(self.channels) do
			self.channels[k] = nil
		end
	end
end

function meta:ping(server)--pings the server
	if not server then
		error("no server for ping")
	else
		self.pinged = false
		self:send("PING "..server)
	end
end


handlers = {}
handlers["PING"] = function(o, prefix, query)
	o:send("PONG :%s", query)
end

handlers["PONG"] = function(o, prefix, query)
	o.pinged = true
end

handlers["001"] = function(o, prefix, me)
	o.authed = true
	o.nick = me
end

handlers["PRIVMSG"] = function(o, prefix, channel, message)
	o:invoke("OnChat", parsePrefix(prefix), channel, message)
end

handlers["ERROR"] = function(o, prefix, message)
	o:invoke("OnDisconnect", message, true)
	o:shutdown()
	error(message, 3)
end

--Names list
handlers["353"] = function (o, prefix, me, chanType, channel, names)
	if o.track_users then
		o.channels[channel] = o.channels[channel] or {users = {}, type = chanType}
		local users = o.channels[channel].users
		for nick in names:gmatch("(%S+)") do
			local access, name = parseNick(nick)
			users[name] = {access = access}
		end
	end
end


--end of NAMES
handlers["366"] = function(o, prefix, me, channel, msg)
	if o.track_users then
		o:invoke("NameList", channel, msg)
	end
end
