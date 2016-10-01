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


local sql = require("lsqlite3")
local db = sql.open("db.sqlite3")

local suc = db:exec([[
	DROP TABLE IF EXISTS 'session';
	CREATE TABLE session(sessionid CHAR(32) PRIMARY KEY, username TEXT UNIQUE NOT NULL, lastaccess BIGINT NOT NULL);

	DROP TABLE IF EXISTS 'psession';
	CREATE TABLE psession(sessionid CHAR(32) PRIMARY KEY, username TEXT UNIQUE NOT NULL);

	DROP TABLE IF EXISTS 'accounts';
	CREATE TABLE accounts(userid INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL, email TEXT NOT NULL, active BOOLEAN DEFAULT 1, oauth TEXT);
		INSERT INTO accounts VALUES(NULL, "columna1", "thecolumna@gmail.com", 1, NULL);
    INSERT INTO accounts VALUES(NULL, "altenius", "jacobjm18@gmail.com", 1, NULL);
	]])


if suc ~= sql.OK then
  error(db:errmsg())
end

db:close()



local permdb = sql.open("permissions.sqlite3")
local suc = permdb:exec([[
DROP TABLE IF EXISTS 'user_permissions';
CREATE TABLE user_permissions(user TEXT, channel TEXT, permission TEXT);
INSERT INTO user_permissions VALUES("Altenius", "#columnaTesting", "command.echo");

DROP TABLE IF EXISTS 'group_permissions';
CREATE TABLE group_permissions('group' TEXT, channel TEXT, permission TEXT);

DROP TABLE IF EXISTS 'user_groups';
CREATE TABLE user_groups(user TEXT, channel TEXT, 'group' TEXT);

DROP TABLE IF EXISTS 'group_inherits';
CREATE TABLE group_inherits('group' TEXT, channel TEXT, inherit TEXT);
]])

if suc ~= sql.OK then
  error(permdb:errmsg())
end

permdb:close()
