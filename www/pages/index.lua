<?lua
    if cookies.sessionId then
        --cookie exists check if it is a valid ID and they can continue
        username = session.check(cookies.sessionId)
        if username then
            --if sessions can expire then refresh session otherwise do nothing
        else --not a valid session
            redirect('../futureindex.lua?error=login')
        end
    else --no cookie
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

    <title>Gdfbot v2</title>

    <!-- Bootstrap Core CSS -->
    <link href="../bower_components/bootstrap/dist/css/bootstrap.min.css" rel="stylesheet">

    <!-- MetisMenu CSS -->
    <link href="../bower_components/metisMenu/dist/metisMenu.min.css" rel="stylesheet">

    <!-- Custom CSS -->
    <link href="../dist/css/sb-admin-2.css" rel="stylesheet">

    <!-- Custom Fonts -->
    <link href="../bower_components/font-awesome/css/font-awesome.min.css" rel="stylesheet" type="text/css">

    <!-- HTML5 Shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
        <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
        <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
    <![endif]-->

</head>

<body>

    <div id="wrapper">

        <!-- Navigation -->
        <nav class="navbar navbar-default navbar-static-top" role="navigation" style="margin-bottom: 0">
            <div class="navbar-header">
                <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
                    <span class="sr-only">Toggle navigation</span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                </button>
                <a class="navbar-brand" href="index.lua">Gdfbot v2</a>
            </div>
            <!-- /.navbar-header -->

          </nav>

        <div id="page-wrapper" style="margin-left: 0">
            <div class="row">
                <div class="col-lg-12">
                    <h1 class="page-header">Choose channel</h1>
                </div>
                <!-- /.col-lg-12 -->
            </div>

            <?lua
              --channels = getUserWebChannels(username)
              channels={"columna1","greendeathflavor","altenius","aweitzman7","xsvarea51"}
              local stats = statistics.getLast()
              for i = 1, math.ceil(#channels/3) do
                  respond('<div class="row">')
                  for j = 1,3 do--oh will go over here
                      if ((i-1)*3)+j <= #channels then
                          local channel = channels[((i-1)*3)+j]
                          local status = (stats.channel[channel] and stats.channel[channel].status) or "No tite"
                          local game = (stats.channel[channel] and stats.channel[channel].game) or "No game"

                          respond([[<div class="col-lg-4">
                                      <div class="panel panel-success">
                                        <div class="panel-heading">
                                          ]]..channel..[[
                                        </div>
                                        <div class="panel-body">
                                          <p><span style="color: #C90003">]] .. game .. "</span> | " .. status .. [[</p>
                                        </div>
                                        <a href="dashboard.lua?channel=]]..url.escape(channel)..[[">
                                          <div class="panel-footer">
                                            <span class="pull-left">Dashboard</span>
                                            <span class="pull-right"><i class="fa fa-arrow-circle-right"></i></span>
                                            <div class="clearfix"></div>
                                          </div>
                                        </a>
                                        <a href="dashboard.lua?channel=]]..url.escape(channel)..[[">
                                        <div class="panel-footer">
                                          ]] .. channel .. [[
                                        </div>
                                        </a>
                                      </div>
                                    </div>]])
                      end
                  end
                respond('</div>')
            end
            ?>

        <!-- /#page-wrapper -->

    </div>
    <!-- /#wrapper -->

    <!-- jQuery -->
    <script src="../bower_components/jquery/dist/jquery.min.js"></script>

    <!-- Bootstrap Core JavaScript -->
    <script src="../bower_components/bootstrap/dist/js/bootstrap.min.js"></script>

    <!-- Metis Menu Plugin JavaScript -->
    <script src="../bower_components/metisMenu/dist/metisMenu.min.js"></script>

    <!-- Custom Theme JavaScript -->
    <script src="../dist/js/sb-admin-2.js"></script>

</body>

</html>
