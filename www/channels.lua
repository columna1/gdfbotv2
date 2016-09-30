<!DOCTYPE html>

<html lang="en">
	<head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
		<title>Channels</title>

		<link href="main.css" rel="stylesheet" type="text/css" />
        <link href="channels.css" rel="stylesheet" type="text/css" />
		<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.6.1/css/font-awesome.min.css">
	</head>
	<body>
		<div class="nav">
			<a class="title-container" href="/dashboard.html"><h2 class="title">GDF Bot</h2></a>
			<div class="menu-container" id="login-nav">
				<a class="menu-button" id="login-button" href="#">
					<span class="fa fa-user fa-fw"></span><span class="caret fa fa-caret-down fa-fw"></span>
				</a>
				<ul class="nav-menu" id="login-menu">
					<li><a href="#"><span class="fa fa-sign-in fa-fw"></span> Login</a></li>
					<li><a href="#"><span class="fa fa-cog fa-fw"></span> Settings</a></li>
					<li class="divider"></li>
					<li><a href="#"><span class="fa fa-sign-out fa-fw"></span> Logout</a></li>
				</ul>
			</div>
		</div>
		<div class="content">
			<h3 class="channels-title">Select a channel</h3>
            <ul class="channels-list">
                <?lua
                    channels={"columna1","greendeathflavor","altenius","aweitzman7","xsvarea51"}
                    local stats = statistics.getLast()
                    
                    for _, channel in ipairs(channels) do
                        local status = (stats.channel[channel] and stats.channel[channel].status) or "No tite"
                        local game = (stats.channel[channel] and stats.channel[channel].game) or "No game"
                        respond([[<li>
                            <a class="channel" href="pages/dashboard.lua?channel=]] .. url.escape(channel) .. [[">
                                <div>
                                    <span class="channel-title">#]] .. channel .. [[</span>
                                    <span class="channel-game">]] .. game .. [[</span>
                                </div>
                                <span class="channel-description">]] .. status .. [[</span>
                            </a>
                        </li>]])
                    end
                ?>
            </ul>
		</div>
	</body>
</html>