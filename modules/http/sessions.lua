session = {}

local sessionTimeout = 3600 * 3 -- 3 hours

local sql = require("lsqlite3")

math.randomseed(os.time())

local chars = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "@", "?", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "_", "~", "!", "`"}

function session.generateId()
  local sessionid = ""
  for i = 1, 32 do
    sessionid = sessionid .. chars[math.random(1, #chars)]
  end

  return sessionid
end

function session.getOAuth()

end

local function checkTempSession(sessionid)
  local prep = sqlAssert(database:prepare("SELECT * FROM session WHERE sessionid=:sessionid"))
  sqlAssert(prep:bind(1, sessionid) == sql.OK)

  local res = prep:step()
  sqlAssert(res ~= sql.ERROR)
  if res == sql.DONE then
    return nil
  end

  local row = prep:get_named_values()
  prep:finalize()
  local expires = row.lastaccess + sessionTimeout

  if os.time() > expires then
    print("cookie expired")
    prep = sqlAssert(database:prepare("DELETE FROM session WHERE sessionid=:sessionid"))
    sqlAssert(prep:bind(1, sessionid) == sql.OK)
    sqlAssert(prep:step() == sql.DONE)
    prep:finalize()
    return nil
  else
    prep = sqlAssert(database:prepare("UPDATE session SET lastaccess=:time WHERE sessionid=:sessionid"))
    sqlAssert(prep:bind(1, sessionid) == sql.OK)
    prep:finalize()
    return row.username
  end
end

function session.check(sessionid) -- returns userid
    --checks both temp sessions and persistant sessions, temporary sessions might dissapear.
    -- check temporary sessions
    local userid = checkTempSession(sessionid)
    if userid then
      return userid
    end

    -- check persistant sessions
    local prep = sqlAssert(database:prepare("SELECT * FROM psession WHERE sessionid=:sessionid"))
    sqlAssert(prep:bind(1, sessionid) == sql.OK)

    local res = prep:step()
    sqlAssert(res ~= sql.ERROR)
    if res == sql.DONE then
      return nil
    end

    local row = prep:get_named_values()
    prep:finalize()
    return row.username
end
