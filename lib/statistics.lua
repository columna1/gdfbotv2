local url = require("socket.url")
local copas = require("copas")
local twitch = require("lib/twitchapi")

local function getActiveChannels()
	local active = {}
	for row in database:nrows("SELECT * FROM accounts WHERE active") do
		table.insert(active, row.username)
	end
	return active
end

local lastStats = {
  channel = {};
  stream = {};
}

local function pullStatistics()
  local channels = getActiveChannels()
  channels = {"columna1", "altenius", "The_Happy_Hobbit"}

  local escapedChannels = {}
  for i,v in ipairs(channels) do
    escapedChannels[i] = url.escape(v)
    channels[v] = true
  end

  lastStats.stream = {}

  local data = twitch.get("streams", "limit=100&channel=" .. table.concat(escapedChannels, ",")) -- max 100 channels
  if data and data.streams then
    for _, stream in pairs(data.streams) do
      lastStats.channel[stream.channel.name] = stream.channel
      lastStats.stream[stream.channel.name] = stream
      channels[stream.channel.name] = nil
    end
  end

  for _, channel in ipairs(channels) do
    if channels[channel] then
      local data = twitch.get("channels/" .. url.escape(channel))
      if data and data.name then
        lastStats.channel[channel] = data
      end
    end
  end
end

module("statistics")

function getLast()
  return lastStats
end

copas.addthread(function()
  while true do
    pullStatistics()
    copas.sleep(120)
  end
end)
