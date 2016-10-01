local json = require("dkjson")
local sql = require("lsqlite3")

local permissionsfile = "databases/permissions.sqlite3"
local permdb = sql.open(permissionsfile)
permdb:exec([[
	CREATE TABLE IF NOT EXISTS user_permissions(user TEXT, channel TEXT, permission TEXT);
	CREATE TABLE IF NOT EXISTS group_permissions('group' TEXT, channel TEXT, permission TEXT);
	CREATE TABLE IF NOT EXISTS user_groups(user TEXT, channel TEXT, 'group' TEXT);
	CREATE TABLE IF NOT EXISTS group_inherits('group' TEXT, channel TEXT, inherit TEXT);
]])

local sqlAssert = sqlAssert

module("permissions")

function removeGroup(group, channel)
	group = group:lower()

	local prep = sqlAssert(permdb:prepare("DELETE FROM group_permissions WHERE \"group\"=:group AND channel=:channel"))
	sqlAssert(prep:bind(1, group) == sql.OK)
	sqlAssert(prep:bind(2, channel) == sql.OK)
	sqlAssert(prep:step() == sql.DONE)
	prep:finalize()

	local prep = sqlAssert(permdb:prepare("DELETE FROM user_groups WHERE \"group\"=:group AND channel=:channel"))
	sqlAssert(prep:bind(1, group) == sql.OK)
	sqlAssert(prep:bind(2, channel) == sql.OK)
	sqlAssert(prep:step() == sql.DONE)
	prep:finalize()

	local prep = sqlAssert(permdb:prepare("DELETE FROM group_inherits WHERE (\"group\"=:group OR inherit=:group) AND channel=:channel"))
	sqlAssert(prep:bind(1, group) == sql.OK)
	sqlAssert(prep:bind(2, channel) == sql.OK)
	sqlAssert(prep:step() == sql.DONE)
	prep:finalize()
end

function removeUser(user, channel)
	user = user:lower()

	local prep = sqlAssert(permdb:prepare("DELETE FROM user_permissions WHERE user=:user AND channel=:channel"))
	sqlAssert(prep:bind(1, group) == sql.OK)
	sqlAssert(prep:bind(2, channel) == sql.OK)
	sqlAssert(prep:step() == sql.DONE)
	prep:finalize()

	local prep = sqlAssert(permdb:prepare("DELETE FROM user_groups WHERE user=:user AND channel=:channel"))
	sqlAssert(prep:bind(1, group) == sql.OK)
	sqlAssert(prep:bind(2, channel) == sql.OK)
	sqlAssert(prep:step() == sql.DONE)
	prep:finalize()
end

function addUserPermission(user, permission, channel)
	user = user:lower()

	-- removeUserPermission(user, permission, channel)

	local prep = sqlAssert(permdb:prepare("INSERT INTO user_permissions VALUES(:user, :channel, :permission)"))
	sqlAssert(prep:bind(1, user) == sql.OK)
	sqlAssert(prep:bind(2, channel) == sql.OK)
	sqlAssert(prep:bind(3, permission) == sql.OK)
	sqlAssert(prep:step() == sql.DONE)
	prep:finalize()
end

function removeUserPermission(user, permission, channel)
	user = user:lower()

	local prep = sqlAssert(permdb:prepare("DELETE FROM user_permissions WHERE user=:user AND channel=:channel AND permission=:permission"))
	sqlAssert(prep:bind(1, user) == sql.OK)
	sqlAssert(prep:bind(2, channel) == sql.OK)
	sqlAssert(prep:bind(3, permission) == sql.OK)
	sqlAssert(prep:step() == sql.DONE)
	prep:finalize()
end

function addUserGroup(user, group, channel)
	user = user:lower()
	group = group:lower()

	local prep = sqlAssert(permdb:prepare("INSERT INTO user_groups VALUES(:user, :channel, :group)"))
	sqlAssert(prep:bind(1, user) == sql.OK)
	sqlAssert(prep:bind(2, channel) == sql.OK)
	sqlAssert(prep:bind(3, group) == sql.OK)
	sqlAssert(prep:step() == sql.DONE)
	prep:finalize()
end

function removeUserGroup(user, group, channel)
	user = user:lower()
	group = group:lower()

	local prep = sqlAssert(permdb:prepare("DELETE FROM user_groups WHERE user=:user AND channel=:channel AND group=:group"))
	sqlAssert(prep:bind(1, user) == sql.OK)
	sqlAssert(prep:bind(2, channel) == sql.OK)
	sqlAssert(prep:bind(3, group) == sql.OK)
	sqlAssert(prep:step() == sql.DONE)
	prep:finalize()
end

function addGroupInherit(group, inherit, channel)
	inherit = inherit:lower()
	group = group:lower()

	local prep = sqlAssert(permdb:prepare("INSERT INTO group_inherits VALUES(:group, :channel, :inherit)"))
	sqlAssert(prep:bind(1, group) == sql.OK)
	sqlAssert(prep:bind(2, channel) == sql.OK)
	sqlAssert(prep:bind(3, inherit) == sql.OK)
	sqlAssert(prep:step() == sql.DONE)
	prep:finalize()
end

function removeGroupInherit(group, inherit, channel)
	inherit = inherit:lower()
	group = group:lower()

	local prep = sqlAssert(permdb:prepare("DELETE FROM group_inherits WHERE \"group\"=:group AND channel=:channel AND inherit=:inherit"))
	sqlAssert(prep:bind(1, group) == sql.OK)
	sqlAssert(prep:bind(2, channel) == sql.OK)
	sqlAssert(prep:bind(3, inherit) == sql.OK)
	sqlAssert(prep:step() == sql.DONE)
	prep:finalize()
end

function addGroupPermission(group, permission, channel)
	group = group:lower()

	-- removeUserPermission(user, permission, channel)

	local prep = sqlAssert(permdb:prepare("INSERT INTO group_permissions VALUES(:group, :channel, :permission)"))
	sqlAssert(prep:bind(1, group) == sql.OK)
	sqlAssert(prep:bind(2, channel) == sql.OK)
	sqlAssert(prep:bind(3, permission) == sql.OK)
	sqlAssert(prep:step() == sql.DONE)
	prep:finalize()
end

function removeUserPermission(group, permission, channel)
	group = group:lower()

	local prep = sqlAssert(permdb:prepare("DELETE FROM group_permissions WHERE \"group\"=:group AND channel=:channel AND permission=:permission"))
	sqlAssert(prep:bind(1, group) == sql.OK)
	sqlAssert(prep:bind(2, channel) == sql.OK)
	sqlAssert(prep:bind(3, permission) == sql.OK)
	sqlAssert(prep:step() == sql.DONE)
	prep:finalize()
end

function groupDoesInherit(group, inherit, channel)
	group = group:lower()
	inherit = inherit:lower()

	local prep = sqlAssert(permdb:prepare("SELECT * FROM group_inherits WHERE \"group\"=:group AND channel=:channel AND inherit=:inherit"))
	sqlAssert(prep:bind(1, group) == sql.OK)
	sqlAssert(prep:bind(2, channel) == sql.OK)
	sqlAssert(prep:bind(3, inherit) == sql.OK)
	local s = prep:step()
	sqlAssert(s ~= sqlite3.ERROR)
	prep:finalize()

	return s == sqlite3.ROW
end

function userIsInGroup(user, inherit, channel)
	user = user:lower()
	inherit = inherit:lower()

	local prep = sqlAssert(permdb:prepare("SELECT * FROM user_groups WHERE user=:user AND channel=:channel AND inherit=:inherit"))
	sqlAssert(prep:bind(1, user) == sql.OK)
	sqlAssert(prep:bind(2, channel) == sql.OK)
	sqlAssert(prep:bind(3, inherit) == sql.OK)
	local s = prep:step()
	sqlAssert(s ~= sqlite3.ERROR)
	prep:finalize()

	return s == sqlite3.ROW
end

function userIsAdmin(user, channel)
	return userIsInGroup(user, "admin", channel)
end

function userIsMod(user, channel)
	return userIsInGroup(user, "mod", channel)
end

local function getGroupInherits(group, channel)
	local inherits = {}

	local prep = sqlAssert(permdb:prepare("SELECT inherit FROM group_inherits WHERE \"group\"=:group AND (channel=:channel OR channel='.global')"))
	sqlAssert(prep:bind(1, group) == sql.OK)
	sqlAssert(prep:bind(2, channel) == sql.OK)

	for row in prep:nrows() do
		table.insert(inherits, row.inherit)
	end
	prep:finalize()

	return inherits
end

local function getUserGroups(user, channel)
	local groups = {}

	local prep = sqlAssert(permdb:prepare("SELECT \"group\" FROM user_groups WHERE user=:user AND (channel=:channel OR channel='.global')"))
	sqlAssert(prep:bind(1, user) == sql.OK)
	sqlAssert(prep:bind(2, channel) == sql.OK)

	for row in prep:nrows() do
		table.insert(groups, row.group)
	end
	prep:finalize()

	return groups
end

function groupHasPermission(group, permission, channel)
	group = group:lower()

	local prep = sqlAssert(permdb:prepare("SELECT * FROM group_permissions WHERE \"group\"=:group AND (channel=:channel OR channel='.global') AND (permission=:permission OR permission='*')"))
	sqlAssert(prep:bind(1, group) == sql.OK)
	sqlAssert(prep:bind(2, channel) == sql.OK)
	sqlAssert(prep:bind(3, permission) == sql.OK)
	local s = prep:step()
	sqlAssert(s ~= sqlite3.ERROR)
	prep:finalize()
	if s == sql.ROW then
		return true
	end

	for _, inherit in ipairs(getGroupInherits(group, channel)) do
		if groupHasPermission(inherit, permission, channel) then
			return true
		end
	end

	return false
end

function userHasPermission(user, permission, channel)
	if groupHasPermission(".all", permission, channel) then
		return true
	end

	user = user:lower()

	local prep = sqlAssert(permdb:prepare("SELECT * FROM user_permissions WHERE user=:user AND (channel=:channel OR channel='.global') AND (permission=:permission OR permission='*')"))
	sqlAssert(prep:bind(1, user) == sql.OK)
	sqlAssert(prep:bind(2, channel) == sql.OK)
	sqlAssert(prep:bind(3, permission) == sql.OK)
	local s = prep:step()
	sqlAssert(s ~= sqlite3.ERROR)
	prep:finalize()
	if s == sql.ROW then
		return true
	end

	for _, group in ipairs(getUserGroups(user, channel)) do
		if groupHasPermission(group, permission, channel) then
			return true
		end
	end

	return false
end

function getUserWebChannels(user)
	local channels = {}

	local prep = sqlAssert(permdb:prepare("SELECT channel FROM user_permissions WHERE user=:user AND (permission='web' OR permission='*')"))
	sqlAssert(prep:bind(1, user) == sql.OK)

	for row in prep:nrows() do
		if not channels[row.channel] then
			table.insert(channels, row.channel)
			channels[row.channel] = true
		end
	end
	prep:finalize()

	return channels
end

return permissions


--[[
function addGroup(group, channel, commands, web, inherits)
	group = group:lower()

	inherits = inherits or {}
	commands = commands or {}
	web = web or {}

	if not groups[channel] then
		groups[channel] = {}
	endFS

	groups[channel][group] = {inherit = inherits, commands = commands, web = web}
end
]]
