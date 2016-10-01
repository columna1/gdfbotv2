local json = require("dkjson")
local http = require("lib/http")

local baseUrl = "https://api.twitch.tv/kraken/"

local twitchapi = {}

function twitchapi.get(api, args)
  local url = baseUrl .. api
  if args then
    url = url .. "?" .. args
  end

  local data = http.get(url, nil, {"Accept: application/vnd.twitchtv.v3+json"})
  if data then
    local jsondata = json.decode(data)
    return jsondata
  end

  log("could not retrieve twitch api " .. api)
end


return twitchapi
