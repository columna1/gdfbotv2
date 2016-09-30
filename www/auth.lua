<!DOCTYPE html>

<html lang="en">
	<head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        
		<title>GDF Bot Login</title>

		<link href="main.css" rel="stylesheet" type="text/css" />
        <link href="login.css" rel="stylesheet" type="text/css" />
	</head>
	<body>
		<div class="nav">
			<span class="title-container" href="/test.html"><h2 class="title">GDF Bot</h2></span>
			<div class="menu-container" id="login-nav">
			</div>
		</div>
        <div class="login-content">
            <?lua
                if args.args.error then
                    respond('<p class="login-error">' .. ((args.args.error == "verification" and "Failed to authenticate with Twitch") or (args.args.error == "login" and "You are not authorized to login, please contact an admin to setup an account") or "Unknown error") .. '</p>')
                end
            ?>
            <p class="login-title">Login with Twitch to continue</p>
            <div class="connect-button">
                <a href="https://api.twitch.tv/kraken/oauth2/authorize?response_type=code&client_id=dzyhrtippxss3fpi4o5h6wcgauez20y&redirect_uri=http://localhost:8080/login.lua&scope=user_read">
                    <img src="/twitch_connect.png" />
                </a>
            </div>
            <p class="login-info">To register please contact an admin</p>
        </div>
	</body>
</html>