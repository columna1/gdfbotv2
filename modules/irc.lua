require("lib/irc")
local copas = require("copas")

local Password = "oauth:" .. maincfg.Oauth
local channelsFile = "channels.txt"
local channels = {}

local function loadChannels()
	file = io.open(channelsFile,"r")
	if file then
		for line in file:lines() do
			line = line:gsub("\r", "")
			table.insert(channels,line)
			globalvars[line] = {}
		end
		file:close()
	end
end

local function saveChannels()
	file = io.open(channelsFile,"w")
	if file then
		for i = 1,#channels do
			file:write(channels[i].."\n")
		end
		file:close()
	end
end

loadChannels()
local function ircThread()
	while true do
		local succ, err = pcall(function()
			ircsocket = irc.new{nick = maincfg.IrcNick}
			ircsocket:connect({
				host = maincfg.IrcServer;
				port = 6667;
				password = Password;
				secure = false;
			})
			
			ircsocket.track_users = true
			log("connected to irc")
			
			for _, channel in ipairs(channels) do
				ircsocket:join(channel)
				log("joining " .. channel)
			end
			
			while running do
				ircsocket:think()
			end
		end)
		if not succ then
			log("IRC error: " .. err .. ", reconnecting in 10 seconds")
			copas.sleep(10)
		end
	end
end

function sendIrcChat(channel, message)
	if ircsocket and ircsocket.authed then
		ircsocket:sendChat(channel, message)
	end
end

copas.addthread(ircThread)
