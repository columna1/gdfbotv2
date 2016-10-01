require("lib/irc")
local copas = require("copas")

local function osuThread()
	while true do
		local succ, err = pcall(function()
			osuirc = irc.new{nick = maincfg.OsuNick, username = maincfg.OsuNick}
			osuirc:connect({
				host = maincfg.OsuIrcServer;
				port = 6667;
				password = maincfg.OsuPassword;
				secure = false;
			})
			
			log("connected to osu irc")
			
			while running do
				osuirc:think()
			end
		end)
		if not succ then
			log("Osu IRC error: " .. err .. ", reconnecting in 10 seconds")
			copas.sleep(10)
		end
	end
end

function sendOsuChat(channel, message)
	if osuirc and osuirc.authed then
		osuirc:sendChat(channel, message)
	end
end


copas.addthread(osuThread)
