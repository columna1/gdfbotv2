<?lua
index="auth.lua"

--if get variable "code" is set then continue otherwise redirect to index/login
if not args.args.code then
	redirect(index)
else
	--if they haven't been redirected then check and get access token with a post
	--http.request({url = "https://url", method = "POST"}, body)

	data = https.post("https://api.twitch.tv/kraken/oauth2/token",
	 "client_id=dzyhrtippxss3fpi4o5h6wcgauez20y"
	.."&client_secret=pt9h7evps1rose9okpgsszowyamm8ea"
	.."&grant_type=authorization_code"
	.."&redirect_uri=http://localhost:8080/login.lua"
	.."&code="..args.args.code)--state not implemented right now probably will later

	--data='{"access_token":"xohwvr2mazdmtv0knazpmma18hx4j9","refresh_token":"eyJfaWQiOiIxMzA4ODk3MzUiLCJfdXVpZCI6IjQ5YmI4MWMwLTcwOWYtNGY3Yy1hZDYzLWU3MjZkMGU0YThiNyJ9%7QdS9X1rdAvGbYtgRtW7KJ4yHKDIA3gbU26ZWihgoRo=","scope":["user_read"]}'

	--if access token request is successful then check the email returned
	if data then
		jsondata = json.decode(data)
		if not jsondata.error then
			data2 = https.get("https://api.twitch.tv/kraken/user",nil,{Accept="application/vnd.twitchtv.v3+json",Authorization="OAuth "..jsondata.access_token})
			--data2 = '{"display_name":"Columna1","_id":23717732,"name":"columna1","type":"user","bio":null,"created_at":"2011-07-28T20:29:05Z","updated_at":"2016-03-16T21:00:35Z","logo":null,"_links":{"self":"https://api.twitch.tv/kraken/users/columna1"},"email":"thecolumna@gmail.com","partnered":false,"notifications":{"push":true,"email":false}}'
			jsondata2 = json.decode(data2)
			--if email is correct then log in
			--check email
			username = false
			--db:exec('SELECT EXISTS(SELECT 1 FROM accounts WHERE email="thecolumna@gmail.com" LIMIT 1);',test,'test_udata')
			--if email is not a valid user then show error page

			local channels = permission.getUserWebChannels(jsondata2.name)
			if #channels ~= 0 then
				username = jsondata2.name
			else
				local prep = sql.assert(database:prepare("SELECT userid, username FROM accounts WHERE email=:email"))
				sql.assert(prep:bind(1, jsondata2.email) == sql.OK)

				-- for row in database:nrows('SELECT username FROM accounts WHERE email="'..jsondata2.email..'"') do
				for row in prep:nrows() do
					if #row <=1 then
						username=row.username
					end
				end
				prep:finalize()
			end
		end
	else
		--if access token request fails show error page
		redirect(index..'?error=verification')
	end
	--if user does not exist then show error page
	if not username then

		print("no")
		redirect(index..'?error=login')
	else
		--set value in sessions table
		--user is logged in, set cookie, add into session table, and redirect to channel select page
		--setCookie(name, value, expires)

		prep = sql.assert(database:prepare("DELETE FROM session WHERE username=:username"))
        sql.assert(prep:bind(1, username) == sql.OK)
        sql.assert(prep:step() == sql.DONE)
        prep:finalize()

		prep = sql.assert(database:prepare("INSERT INTO session VALUES(:sessionid, :username, :lastaccess)"))
		local id = session.generateId()
		sql.assert(prep:bind(1, id) == sql.OK)
		sql.assert(prep:bind(2, username) == sql.OK)
		sql.assert(prep:bind(3, os.time()) == sql.OK)
		sql.assert(prep:step() == sql.DONE)
		prep:finalize()

		local cookieDate = os.date("%a, %d-%b-%Y %H:%M:%S GMT", os.time() + (3600 * 24 * 365)) -- 1 year away

		setCookie("sessionId", id, cookieDate)
		redirect("channels.lua")
	end
end
?>
