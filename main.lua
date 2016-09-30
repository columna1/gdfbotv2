--[[ todo list

admins/bot amdins = pepole the channel owner gives admin access to
global bot admin? somewhat limited permissions can but can edit all channels important for moderation/maitenance
chanel owner = has somewhat elevated permissions and can edit their channel
super admin = us/owners that can edit absolutely anything and everthing
	possible second verification step in case twitch account is comprimised (we do not want ANYONE to get into this account/access level
        Absolutely manual adding of super amdmins, cannot add through gui or any similar process)

create a web gui

	first page after login shows available channels to look at/view
		only shows channels the user is authorised to access

	control panel/chanel pages are as follows


	global variable section
	console for chat
		send messages as logged in user or bot?
	command list
	command run button
	command forget button
	console for command editing/creating
		easy command adding
			whisper support for easy commands
	configurable whitelist/blacklist for individual commands?
	info console for admin info (ex. "Command [command here] has been registered"
	function inforrmation panel?
	admin editing
	userlist
	mute button/indicator
	save button/indicator
	reload button
	admin mode button/indicator (only admins can activate commands)
	global mute button
	add quit button(With warning bot)
	second command type box/edit
	dropdown box for command type
	chat history/logs?
	bot admins have access to webconsole? aka can chat using bot
	bootstrap template
		add different statistics
			uptime/viewers scrolling graph
		draggable/reorderable elements? (in the far future)
			saving settings/positions for such elements
			dragging between tabs
			making new tabs/deleting tabs
			can configure what their bot admins have access to
	request commands button???
	support devs button (paypal) -maybe

colors DONE

twitch intergration
	logging into the web panel
	editing things like title etc
	registering new users? -does a superadmin/owner need to add new users?
	statistics with bootstrap

channel specific commands
	three/four types of commands
		commands that get called every message
		commands that get called every x ammount of seconds
		commands that get called when it sees a keyword
		simple commands that spit out text when it sees the keyword
	disabling commands
	option for commands to be admin only DONE
	option for commands to be mod only DONE

global commands? DONE

administration
	channel specific bot admins DONE
	option to allow mods to be bot admins
	channel owner is always bot admin
	administration commands
		edit/delete/veiw commands etc...
	copy commands between servers/channels

Channels
	bot can be in multiple channels at once, each with seperate settings/commands
	bot superadmins can edit all channels
Servers
	bot can be in multiple servers.
		settings can be much like seperate channels?

functions for commands
	http grabbing functions DONE
	https grabbing functions DONE
	json decode/encode functions DONE
	--get list of users
	isAdmin DONE
	isMod DONE
	name/info about user
	can call other commands
	sandboxed to protect bot
	edit other commands?
	variables
	whisper support
	sending messages
		can send to different servers/channels (only superAdmins can register commands with these)
		can whisper to people
		limit on number of messages/freequency of messages (prevents global timeouts
	permission system? DONE
		admin permission - access to extra functions and other things
		channel permission - access only to general functions

Pre made commands (these will all not be included in channels by default and owners can import them and enable them from a global list)
	Youtube request system
		request, with length, and number of request limits(configurable)
	configurable request system (for things like mario maker levels or osu songs)
		with table that updates automatically
	vote/poll system
	raffle system (like giveaways)
	coin/point/level system
		ability to change name of points/coins as well as rates for different users/ranks of users
		ability to set a user's point level
		commands for users to give points to others
	speedrun.com leaderboard retrieval system for !wr !pb etc, automatically grabs game from twitch
		option to change username/game for retrieval
	Word blacklist for auto ban
		configurable list, configurable timeout/ban for each
		URL whitelist/blacklist
		configurable URLS, configurable timeout/ban
	sound playing
		add sound files (with URLS/youtube) to play when activated with a commands

global/channel variables
	commands can register and edit/view variables
	variables get saved to disk whenever edited

Backend
	save command lists as different files (ex "columna1Commands.txt")
	save/load channels
	webserver DONE
		lua integration DONE mostly
		sql/database for statistics/setting storage for web interface
	modules for different functions that can be changed/loaded/removed/added FULLY dynamically (hotswapable)
		includes special cases when other modules that are depended on are missing/not loaded
		main bot can still run if there is an error in one or more of the modules\

	sessions
		just generate 32 char ID that expires a certain time after they last accessed anything 3h?
	database -this will have a lua file that can create/set up the database from scratch
				IMPORTANT TO BACK UP THIS DATABASE REGULARLY (probably)
		tables
			entries
			---------
		session (session and persistant session entries will be removed when log out button is used)
			ID, username, twitch OAUTH?, time last accessed, time logged on?
		persistant session (remember me box)
			ID, username, Twitch OAUTH?, time last accessed --NOT AVAILABLE FOR SUPER ADMINS idk why but whatever seems like a good idea
		settings(maybe)
			TBD
		--rest will be for statistics/application specific uses(like youtube/music request/queue system)
		viewer count --will reset every stream
			count, time
	versioning control/backups with restore option (almost for fun)
		uses diff/patch to save space?



	IRC prefixes
	+ = turbo
	@ = mod
	~ = owner
	% = sub
	^ = bot
]]--

local function isWindows()
  return type(package) == 'table' and type(package.config) == 'string' and package.config:sub(1,1) == '\\'
end

if isWindows() then
	package.path = ".\\?.lua;.\\luajit\\lua\\?.lua"
	package.cpath = ".\\?.dll;.\\luajit\\?.dll"
else
	-- package.path = "./?.lua;./luajit/lua/?.lua"
	-- package.cpath = "./?.dll;./luajit/?.dll"
end

startTime = os.time()

local colors = require("ansicolors")

ircEnabled = true

local tArgs = {...}
for i,v in ipairs(tArgs) do
	if v == "-noirc" then
		ircEnabled = false
	end
end

--lets test for user list
require("irc")
local copas = require("copas")
local sleep = require "socket".sleep
IrcNick = "GdfBot"
OsuNick = "columna1"
--IrcNick = "gdfbot"
--ladle.init(80)
if ircEnabled then
	s = irc.new{nick = IrcNick}
  osuirc = irc.new{nick = OsuNick, username = OsuNick}
end
IrcServer = "irc.chat.twitch.tv"
OsuIrcServer = "irc.ppy.sh"
OsuPassword = "1c6a2c47"

local file = io.open("oauth.txt", "r")
if not file then
  print("oauth.txt does not exist")
  Oauth = ""
else
  Oauth = file:read("*a")
  file:close()
end

Password = "oauth:" .. Oauth

--IrcChannel = "#greendeathflavor"
--IrcChannel = "#brenbread"
--IrcChannel = "#computercraft"
channelsFile = "channels.txt"
channels = {}
globalvars = {}

function loadChannels()
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

function saveChannels()
	file = io.open(channelsFile,"w")
	if file then
		for i = 1,#channels do
			file:write(channels[i].."\n")
		end
		file:close()
	end
end

local timers = {}

function registerTimer(func, interval, repeating)
	local id = #timers + 1
	timers[id] = {
		func = func;
		next = os.clock() + interval;
		interval = interval;
		repeating = repeating;
	}

	return id
end

function removeTimer(id)
	timers[id] = nil
end

function log(...)
	local text = {...}
	text = "[%{green}" .. os.date("%a %Y-%m-%d %I:%M:%S %p") .. "%{reset}] " .. table.concat(text, "   ")

	--[[local file = io.open("log.txt", "a")
	file:write(text:gsub("%%{.-}", "") .. "\n")
	file:close()]]

	print(colors(text))
end

function loadModule(name)
	local func, err = loadfile(("modules/%s.lua"):format(name))
	if not func then
		error("Could not load handlers.lua: " .. err, 0)
	end
	func()
end

loadModule("util")
loadModule("permissions")
loadModule("http")
loadModule("handlers")
loadModule("commands")

local sql = require("lsqlite3")
database = sql.open("db.sqlite3")

function sqlAssert(...)
  local v = {...}
  if v[1] then
    return unpack(v)
  else
    error(database:errmsg(), 2)
  end
end;

if ircEnabled then
  loadChannels()
  copas.addthread(function()
    s:connect({
      host = IrcServer;
      port = 6667;
      password = Password;
      secure = false;
    })

  	s.track_users = true
    log("connected to irc")

    for _, channel in ipairs(channels) do
      s:join(channel)
      log("joining " .. channel)
    end

    while running do
      s:think()
    end
  end)

  copas.addthread(function()
    osuirc:connect({
      host = OsuIrcServer;
      port = 6667;
      password = OsuPassword;
      secure = false;
    })

    log("connected to osu irc")

    while running do
      osuirc:think()
    end
  end)
end

function printTable(tbL)
	print(serialize(tbl))
end

loadModule("twitchapi")
loadModule("statistics")

running = true

while running do
  copas.step()
end
