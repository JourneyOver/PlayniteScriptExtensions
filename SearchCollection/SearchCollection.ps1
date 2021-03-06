function global:GetGameMenuItems()
{
    param(
        $menuArgs
    )
   
    $BingImagesScreenshot_MenuItem = New-Object Playnite.SDK.Plugins.ScriptGameMenuItem
    $BingImagesScreenshot_MenuItem.Description =  "Bing Images Screenshot"
    $BingImagesScreenshot_MenuItem.FunctionName = "SearchBingImagesScreenshot"
    $BingImagesScreenshot_MenuItem.MenuSection = "Search"

    $BingImagesWallpaper_MenuItem = New-Object Playnite.SDK.Plugins.ScriptGameMenuItem
    $BingImagesWallpaper_MenuItem.Description =  "Bing Images Wallpaper"
    $BingImagesWallpaper_MenuItem.FunctionName = "SearchBingImagesWallpaper"
    $BingImagesWallpaper_MenuItem.MenuSection = "Search"

    $GoogleImagesScreenshot_MenuItem = New-Object Playnite.SDK.Plugins.ScriptGameMenuItem
    $GoogleImagesScreenshot_MenuItem.Description =  "Google Images Screenshot"
    $GoogleImagesScreenshot_MenuItem.FunctionName = "SearchGoogleImagesScreenshot"
    $GoogleImagesScreenshot_MenuItem.MenuSection = "Search"

    $GoogleImagesWallpaper_MenuItem = New-Object Playnite.SDK.Plugins.ScriptGameMenuItem
    $GoogleImagesWallpaper_MenuItem.Description =  "Google Images Wallpaper"
    $GoogleImagesWallpaper_MenuItem.FunctionName = "SearchGoogleImagesWallpaper"
    $GoogleImagesWallpaper_MenuItem.MenuSection = "Search"
    
    $Metacritic_MenuItem = New-Object Playnite.SDK.Plugins.ScriptGameMenuItem
    $Metacritic_MenuItem.Description =  "Metacritic"
    $Metacritic_MenuItem.FunctionName = "SearchMetacritic"
    $Metacritic_MenuItem.MenuSection = "Search"

    $PCGamingWiki_MenuItem = New-Object Playnite.SDK.Plugins.ScriptGameMenuItem
    $PCGamingWiki_MenuItem.Description =  "PCGamingWiki"
    $PCGamingWiki_MenuItem.FunctionName = "SearchPCGamingWiki"
    $PCGamingWiki_MenuItem.MenuSection = "Search"

    $SteamDB_MenuItem = New-Object Playnite.SDK.Plugins.ScriptGameMenuItem
    $SteamDB_MenuItem.Description =  "SteamDB"
    $SteamDB_MenuItem.FunctionName = "SearchSteamDB"
    $SteamDB_MenuItem.MenuSection = "Search"
    
    $SteamGridDB_MenuItem = New-Object Playnite.SDK.Plugins.ScriptGameMenuItem
    $SteamGridDB_MenuItem.Description =  "SteamGridDB"
    $SteamGridDB_MenuItem.FunctionName = "SearchSteamGridDB"
    $SteamGridDB_MenuItem.MenuSection = "Search"
    
    $Twitch_MenuItem = New-Object Playnite.SDK.Plugins.ScriptGameMenuItem
    $Twitch_MenuItem.Description =  "Twitch"
    $Twitch_MenuItem.FunctionName = "SearchTwitch"
    $Twitch_MenuItem.MenuSection = "Search"
    
    $VNDB_MenuItem = New-Object Playnite.SDK.Plugins.ScriptGameMenuItem
    $VNDB_MenuItem.Description =  "VNDB"
    $VNDB_MenuItem.FunctionName = "SearchVNDB"
    $VNDB_MenuItem.MenuSection = "Search"
    
    $Youtube_MenuItem = New-Object Playnite.SDK.Plugins.ScriptGameMenuItem
    $Youtube_MenuItem.Description =  "Youtube"
    $Youtube_MenuItem.FunctionName = "SearchYoutube"
    $Youtube_MenuItem.MenuSection = "Search"
    
    return $BingImagesScreenshot_MenuItem, $BingImagesWallpaper_MenuItem, $GoogleImagesScreenshot_MenuItem, $GoogleImagesWallpaper_MenuItem, $Metacritic_MenuItem, $PCGamingWiki_MenuItem, $SteamDB_MenuItem, $SteamGridDB_MenuItem, $Twitch_MenuItem, $VNDB_MenuItem, $Youtube_MenuItem
}

function global:Invoke-LaunchUrl
{
    param (
        $SearchUrlTemplate
    )
    
    # Set gamedatabase
    $Gamedatabase = $PlayniteApi.MainView.SelectedGames

    # Launch urls of all selected gams
    foreach ($game in $Gamedatabase) {
        $GameName = [uri]::EscapeDataString($($game.name))
        $SearchUrl = $SearchUrlTemplate -f $GameName
        Start-Process $SearchUrl
    }
}

function global:SearchBingImagesWallpaper
{
    # Set dimensions of image search
    $width = '1920'
    $height = '1080'

    # Set Search Url template and invoke Url launch function
    $SearchUrlTemplate = 'https://www.bing.com/images/search?&q={0} Wallpaper&qft=+filterui:imagesize-custom_' + "$width" + '_' + "$height"
    Invoke-LaunchUrl  $SearchUrlTemplate
}

function global:SearchBingImagesScreenshot
{
    # Set dimensions of image search
    $width = '1920'
    $height = '1080'

    # Set Search Url template and invoke Url launch function
    $SearchUrlTemplate = 'https://www.bing.com/images/search?&q={0} Screenshot&qft=+filterui:imagesize-custom_'+ "$width" + '_' + "$height"
    Invoke-LaunchUrl  $SearchUrlTemplate
}
function global:SearchGoogleImagesWallpaper
{
    # Set dimensions of image search
    $width = '1920'
    $height = '1080'

    # Set Search Url template and invoke Url launch function
    $SearchUrlTemplate = 'https://www.google.com/search?q={0} Wallpaper imagesize:' + "$width" + 'x' + "$height" + '&tbm=isch'
    Invoke-LaunchUrl  $SearchUrlTemplate
}

function global:SearchGoogleImagesScreenshot
{
    # Set dimensions of image search
    $width = '1920'
    $height = '1080'

    # Set Search Url template and invoke Url launch function
    $SearchUrlTemplate = 'https://www.google.com/search?q={0} Screenshot imagesize:' + "$width" + 'x' + "$height" + '&tbm=isch'
    Invoke-LaunchUrl  $SearchUrlTemplate	
}
function global:SearchMetacritic
{
    # Set Search Url template and invoke Url launch function
    $SearchUrlTemplate = 'https://www.metacritic.com/search/game/{0}/results' 
    Invoke-LaunchUrl  $SearchUrlTemplate
}

function global:SearchSteamGridDB
{
    # Set Search Url template and invoke Url launch function
    $SearchUrlTemplate = 'https://www.steamgriddb.com/search/grids?term={0}'
    Invoke-LaunchUrl  $SearchUrlTemplate
}

function global:SearchTwitch
{
    # Set Search Url template and invoke Url launch function
    $SearchUrlTemplate = 'https://www.twitch.tv/search?term={0}'
    Invoke-LaunchUrl  $SearchUrlTemplate
}

function global:SearchVNDB
{
    # Set Search Url template and invoke Url launch function
    $SearchUrlTemplate = 'https://vndb.org/v/all?q={0}'
    Invoke-LaunchUrl  $SearchUrlTemplate
}

function global:SearchYoutube
{
    # Set Search Url template and invoke Url launch function
    $SearchUrlTemplate = 'https://www.youtube.com/results?search_query={0}'
    Invoke-LaunchUrl  $SearchUrlTemplate
}

function global:SearchPCGamingWiki
{
    # Set GameDatabase
    $GameDatabase = $PlayniteApi.MainView.SelectedGames | Where-Object {$_.platform.name -eq "PC"}
    if ($GameDatabase.count -lt 1)
    {
        $PlayniteApi.Dialogs.ShowMessage("No PC games selected", "Search Collection");
        exit
    }

    foreach ($game in $GameDatabase) {
        if ($game.Source.name -eq "Steam" )
        {
            $SearchUrl = 'https://pcgamingwiki.com/api/appid.php?appid=' + "$($game.GameId)"
            Start-Process  $SearchUrl
        }
        else
        {
            $SearchUrl = 'http://pcgamingwiki.com/w/index.php?search=' + "$($game.name)"
            Start-Process  $SearchUrl
        }
    }
}

function global:SearchSteamDB
{
    # Set gamedatabase
    $GameDatabase = $PlayniteApi.MainView.SelectedGames | Where-Object {$_.platform.name -eq "PC"}
    if ($GameDatabase.count -lt 1)
    {
        $PlayniteApi.Dialogs.ShowMessage("No PC games selected", "Search Collection");
        exit
    }

    # Launch Urls
    foreach ($game in $GameDatabase) {
        if ($game.Source.name -eq "Steam" )
        {
            $SearchUrl = 'https://steamdb.info/app/' + "$($game.GameId)"
            Start-Process  $SearchUrl
        }
        else
        {
            $SearchUrl = 'https://steamdb.info/search/?a=app&q=' + "$($game.name)" + '&type=1&category=0'
            Start-Process  $SearchUrl
        }
    }
}