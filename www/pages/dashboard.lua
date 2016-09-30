<?lua
    if cookies.sessionId then
        --cookie exists check if it is a valid ID and they can continue
        username = session.check(cookies.sessionId)
        if username then
            local stats = statistics.getLast()
            local stream = stats.stream[args.args.channel or ""]
            if stream then
              if stream.created_at then
                local year, month, day, hour, minute, second = stream.created_at:match("(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)Z")
                if year then
                  seconds = os.time({year = year, month = month, day = day, hour = hour, min = minute, sec = second})
                  local curDate = os.date("!*t")
                  local isdst = os.date("*t").isdst
                  curDate.isdst = isdst
                  local curTime = os.time(curDate)
                  seconds = os.difftime(curTime, seconds)
                end
              end
            end
            --if sessions can expire then refresh session otherwise do nothing
        else--not a valid session
            redirect('../futureindex.lua?error=login')
        end
    else--no cookie
        redirect('../futureindex.lua?error=login')
    end
?>
<!DOCTYPE html>
<html lang="en">

<head>

    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="">
    <meta name="author" content="">

    <title>Gdfbot v2 Admin</title>

    <!-- Bootstrap Core CSS -->
    <link href="../bower_components/bootstrap/dist/css/bootstrap.min.css" rel="stylesheet">

    <!-- MetisMenu CSS -->
    <link href="../bower_components/metisMenu/dist/metisMenu.min.css" rel="stylesheet">

    <!-- Timeline CSS -->
    <link href="../dist/css/timeline.css" rel="stylesheet">

    <!-- Custom CSS -->
    <link href="../dist/css/sb-admin-2.css" rel="stylesheet">

    <!-- Morris Charts CSS -->
    <link href="../bower_components/morrisjs/morris.css" rel="stylesheet">

    <!-- Custom Fonts -->
    <link href="../bower_components/font-awesome/css/font-awesome.min.css" rel="stylesheet" type="text/css">

    <!-- HTML5 Shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
        <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
        <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
    <![endif]-->

    <?lua if seconds then
    respond([[
    <script>
      var secondsTotal = ]] .. seconds .. [[;
      var uptime;

      function pad(num) {
        var s = num.toString();
        if (s.length === 1) {
          s = "0" + s;
        }
        return s;
      }

      function update() {
        secondsTotal += 1;

        if (uptime !== undefined) {
          var minutes = secondsTotal / 60;
          var seconds = Math.floor(secondsTotal) % 60;
          var hours = minutes / 60;
          minutes = Math.floor(minutes) % 60;
          var days = Math.floor(hours / 24);
          hours = Math.floor(hours) % 24;
          uptime.innerHTML = pad(days) + ":" + pad(hours) + ":" + pad(minutes) + ":" + pad(seconds);
        }

        setTimeout(update, 1000);
      }

      function onLoad() {
        uptime = document.getElementById("uptime");
      }

      setTimeout(update, 1000);
      window.onload = onLoad;
    </script>]]) end ?>
</head>

<body>

    <div id="wrapper">

        <?lua
		local file = io.open("pages/navbar.html","r")
		local navbar = file:read("*a")
        file:close()
		respond(navbar)
		?>

        <div id="page-wrapper">
            <div class="row">
                <div class="col-lg-12">
                    <h1 class="page-header">Dashboard</h1>
                </div>
                <!-- /.col-lg-12 -->
                <div class="col-lg-3 col-md-6">
                    <div class="panel panel-primary">
                        <div class="panel-heading">
                            <div class="row">
                                <div class="col-xs-3">
                                    <i class="glyphicon glyphicon-time fa-5x"></i>
                                </div>
                                <div class="col-xs-9 text-right">
                                    <div class="huge" id="uptime"><!-- ?lua
                                        local minutes = seconds / 60
                                        seconds = math.floor(seconds) % 60
                                        local hours = minutes / 60
                                        minutes = math.floor(minutes) % 60
                                        local days = math.floor(hours / 60)
                                        hours = math.floor(hours) % 24
                                        respond(string.format("%02u", days) .. ":" .. string.format("%02u", hours) .. ":" .. string.format("%02u", minutes) .. ":" .. string.format("%02u", seconds))
                                    ?--><?lua if seconds then respond("Loading") else respond("Not streaming") end ?></div>
                                    <div>Uptime</div>
                                </div>
                            </div>
                        </div>
                        <a href="#">
                            <div class="panel-footer">
                                <span class="pull-left">View Statistics</span>
                                <span class="pull-right"><i class="fa fa-arrow-circle-right"></i></span>
                                <div class="clearfix"></div>
                            </div>
                        </a>
                    </div>
                    <!-- add in twitch chat -->
                    <div class="embed-responsive embed-responsive-4by3">
                      <iframe frameborder="0"
                              scrolling="no"
                              id="chat_embed"
                              src="http://www.twitch.tv/<?lua respond(args.args.channel or "") ?>/chat">
                      </iframe>
                    </div>
                </div>
            </div>
        </div>
        <!-- /#page-wrapper -->

    </div>
    <!-- /#wrapper -->

    <!-- jQuery -->
    <script src="../bower_components/jquery/dist/jquery.min.js"></script>

    <!-- Bootstrap Core JavaScript -->
    <script src="../bower_components/bootstrap/dist/js/bootstrap.min.js"></script>

    <!-- Metis Menu Plugin JavaScript -->
    <script src="../bower_components/metisMenu/dist/metisMenu.min.js"></script>

    <!-- Morris Charts JavaScript -->
    <!-- <script src="../bower_components/raphael/raphael-min.js"></script>
    <script src="../bower_components/morrisjs/morris.min.js"></script>
    <script src="../js/morris-data.js"></script>
-->

    <!-- Custom Theme JavaScript -->
    <script src="../dist/js/sb-admin-2.js"></script>

</body>

</html>
