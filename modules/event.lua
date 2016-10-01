if not ircEnabled then return end

local copas = require("copas")
copas.http = require("copas.http")
local coxpcall = require("coxpcall")
local json = require("dkjson")

local events = {}

event = {}

function event.add(channel, event, func)
	if not events[channel] then
		events[channel] = {}
	end
	if not events[channel][event] then
		events[channel][event] = {func}
	else
		table.insert(events[channel][event], func)
	end
end

function event.call(channel, event, ...)
	if events[channel] and events[channel][event] then
		for _, func in ipairs(events[channel][event]) do
			local succ, err = coxpcall.pcall(func, ...)
			if not succ then
				sendIrcChat(channel, "Error running event " .. event .. ": " .. err)
			end
		end
	end
end

event.add("#altenius", "chat", function(user, message)
	local status = {[-2]="[graveyard]",[-1]="[WIP]",[0]="[pending]",[1]="[ranked]",[2]="[approved]",[3]="[qualified]"}
	message = message:lower()
	local sstart, send = message:find("https?://osu.ppy.sh/[sb]/")
	if sstart then
		local data, err = copas.http.request("https://osu.ppy.sh/api/get_beatmaps", "&k=6f7ed355a7b42bfe50eb01a3f40bc35be8ced14f&" .. message:sub(send - 1, send - 1) .. "=" .. message:sub(send + 1))
		if data then
			local jdata = json.decode(data)
			if jdata then
				sendOsuChat("columna1", status[tonumber(jdata[1].approved)].." [" .. message:sub(sstart) .." " .. jdata[1].artist .. " - " .. jdata[1].title .. "] " .. string.format("%.2f", tonumber(jdata[1].difficultyrating)) .. " stars " .. jdata[1].hit_length .. " seconds long") -- todo: format seconds into minutes if long enough
			else
				log("error: could not parse json")
			end
		else
			log("error: " .. err)
		end
	end
end)

local function chats(user, channel, message)
	log("[%{yellow}" .. channel .. "%{reset}] %{cyan}" .. user.nick .. "%{reset}: " .. message)
	if message:sub(1, 1) == "!" then
		local pos = message:find(" ")
		local command = message:sub(2, pos and pos - 1)
		if userHasPermission(user.nick, "command." .. command, channel) then
			callCommand(command, user, channel, pos and message:sub(pos + 1) or "")
		end
	end

	event.call(channel, "chat", user, message)
end
ircsocket:hook("OnChat",chats)

function raw(line)
	 print(line)
end
-- ircsocket:hook("OnRaw",raw)

function lists(tab,msg)
	--for users
	--[[printTable(ircsocket.channels[IrcChannel].users)
	for i,k in pairs(ircsocket.channels[IrcChannel].users) do
		if k.access.op then print(i.." is op")
		elseif k.access.halfop then print(i.." is halfop")
		elseif k.access.voice then print(i.." has voice?")
		else print(i) end
	end]]
end
ircsocket:hook("NameList",lists)
