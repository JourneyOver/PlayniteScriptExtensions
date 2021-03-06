function global:GetMainMenuItems
{
    param($menuArgs)

    $menuItem1 = New-Object Playnite.SDK.Plugins.ScriptMainMenuItem
    $menuItem1.Description = "Add Play Actions and feature"
    $menuItem1.FunctionName = "Add-PlayActionsAndFeature"
    $menuItem1.MenuSection = "@NVIDIA Geforce NOW Enabler"
    
    $menuItem2 = New-Object Playnite.SDK.Plugins.ScriptMainMenuItem
    $menuItem2.Description = "Add feature to enabled games"
    $menuItem2.FunctionName = "Add-Feature"
    $menuItem2.MenuSection = "@NVIDIA Geforce NOW Enabler"

    $menuItem3 = New-Object Playnite.SDK.Plugins.ScriptMainMenuItem
    $menuItem3.Description = "Remove Play Actions from all games"
    $menuItem3.FunctionName = "Remove-PlayActions"
    $menuItem3.MenuSection = "@NVIDIA Geforce NOW Enabler"

    $menuItem4 = New-Object Playnite.SDK.Plugins.ScriptMainMenuItem
    $menuItem4.Description = "Set NVIDIA Geforce NOW enabled games as installed"
    $menuItem4.FunctionName = "Set-InstallationStatus"
    $menuItem4.MenuSection = "@NVIDIA Geforce NOW Enabler"

    return $menuItem1, $menuItem2, $menuItem3, $menuItem4
}

function global:Invoke-GeforceNowEnabler
{
    param (
        [bool]$AddPlayAction
    )

    # Set GameDatabase
    $GameDatabase = $PlayniteApi.Database.Games | Where-Object {$_.Platform.name -eq "PC"}  | Where-Object {$_.source.name -match "(Steam|Epic|Uplay|Origin)"}
    
    # Create "NVIDIA GeForce NOW" Feature
    $featureName = "NVIDIA GeForce NOW"
    $feature = $PlayniteApi.Database.Features.Add($featureName)
    $featureIds = $feature.Id
    
    # Set NVIDIA GeForce NOW enabled games counters
    $GeForceNowEnabled = 0
    $CounterFeatureAdded = 0
    $CounterFeatureRemoved = 0
    $CounterPlayActionAdded = 0
    $CounterPlayActionRemoved = 0
    
    # Check if NVIDIA GeForce NOW is installed
    if ($AddPlayAction -eq $true)
    {
        $GeForceNowWorkingPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath "NVIDIA Corporation\GeForceNOW\CEF\"
        $GeForceNowPath = Join-Path -Path $GeForceNowWorkingPath -ChildPath  "GeForceNOWStreamer.exe"
        if (!(Test-Path $GeForceNowPath))
        {
            $PlayniteApi.Dialogs.ShowErrorMessage("NVIDIA GeForce NOW installation not detected, please install NVIDIA GeForce NOW before using this function.", "NVIDIA GeForce NOW Enabler");
            exit
        }
    }
    
    # NVIDIA GeForce NOW compatible game list download and convert
    $SupportedGamesUri = "https://static.nvidiagrid.net/supported-public-game-list/gfnpc.json"
    try {
        [array]$SupportedGames = Invoke-WebRequest $SupportedGamesUri | ConvertFrom-Json | Where-Object {$_.status -eq "AVAILABLE"}
    } catch {
        $ErrorMessage = $_.Exception.Message
        $PlayniteApi.Dialogs.ShowErrorMessage("Couldn't download NVIDIA GeForce NOW database file. Error: $ErrorMessage", "NVIDIA GeForce NOW Enabler");
        exit
    }
    
    # Generate game names for matching and lists per store
    foreach ($SupportedGame in $SupportedGames) {
        $SupportedGame.title =  $SupportedGame.title -replace '[^\p{L}\p{Nd}]', ''
    }
    $SupportedGamesSteam = $SupportedGames | Where-Object {$_.store -eq "Steam"}
    $SupportedGamesEpic = $SupportedGames | Where-Object {$_.store -eq "Epic"}
    $SupportedGamesUplay = $SupportedGames | Where-Object {$_.store -eq "UPLAY"}
    $SupportedGamesOrigin = $SupportedGames | Where-Object {$_.store -eq "Origin"}
    
    foreach ($Game in $GameDatabase) {
    
        # Generate game name for matching in lists
        $GameName = $($Game.name) -replace '[^\p{L}\p{Nd}]', ''
        $MatchedGame = $null
        
        # Search for matches in support list
        switch ($Game.source.name)
        {
            'Steam' {
                $SteamUrl = 'https://store.steampowered.com/app/{0}' -f $($Game.GameId)
                foreach ($SupportedGame in $SupportedGamesSteam) {
                    if ($SupportedGame.SteamUrl -eq $SteamUrl) 
                    {
                        $MatchedGame = $SupportedGame
                        $GeForceNowEnabled++
                        break
                    }
                }
            }
            'Epic' {
                foreach ($SupportedGame in $SupportedGamesEpic) {
                    if ($SupportedGame.Title -eq $GameName) 
                    {
                        $MatchedGame = $SupportedGame
                        $GeForceNowEnabled++
                        break
                    }
                }
            }
            'Uplay' { 
                foreach ($SupportedGame in $SupportedGamesUplay) {
                    if ($SupportedGame.Title -eq $GameName) 
                    {
                        $MatchedGame = $SupportedGame
                        $GeForceNowEnabled++
                        break
                    }
                }
            }
            'Origin' { 
                foreach ($SupportedGame in $SupportedGamesOrigin) {
                    if ($SupportedGame.Title -eq $GameName) 
                    {
                        $MatchedGame = $SupportedGame
                        $GeForceNowEnabled++
                        break
                    }
                }
            }
            default {
                break
            }
        }

        # Check if game already has the feature and if it has been removed
        if ($Game.Features.name -eq $featureName)
        {
            if (!$MatchedGame)
            {
                $Game.FeatureIds.Remove($featureIds)
                $PlayniteApi.Database.Games.Update($Game)
                $__logger.Info("NVIDIA GeForce NOW Enabler - Feature removed from `"$($Game.name)`"")
                $CounterFeatureRemoved++
            }
        }
        elseif ($MatchedGame)
        {
            # Add feature Id to game
            if ($Game.FeatureIds) 
            {
                $Game.FeatureIds += $featureIds
            }
            else 
            {
                # Fix in case game has null FeatureIds
                $Game.FeatureIds = $featureIds
            }
            
            # Update game in database
            $PlayniteApi.Database.Games.Update($Game)
            $__logger.Info("NVIDIA GeForce NOW Enabler - Feature added to `"$($Game.name)`"")
            $CounterFeatureAdded++
        }
        if ($AddPlayAction -eq $true)
        {
            # Check if game already has GeForce NOW Play Action
            $GfnOtherActions = $Game.OtherActions | Where-Object {$_.Arguments -Match "--url-route=`"#\?cmsId=\d+&launchSource=External`""}
            if ($GfnOtherActions.count -ge 1)
            {
                if (!$MatchedGame)
                {
                    # Remove GeForce NOW Play Actions from game if not found in its database
                    foreach ($PlayAction in $GfnOtherActions) {
                        $Game.OtherActions.Remove($PlayAction)
                        $PlayniteApi.Database.Games.Update($Game)
                        $__logger.Info("NVIDIA GeForce Enabler - Play Action removed from `"$($Game.name)`"")
                        $CounterPlayActionRemoved++
                    }
                }
            }
            elseif ($MatchedGame)
            {
                # Set GeForce NOW launch Arguments
                $PlaActionArguments = "--url-route=`"#?cmsId=$($MatchedGame.id)&launchSource=External`""
            
                # Create PlayAction
                $GameAction = [Playnite.SDK.Models.GameAction]::New()
                $GameAction.Name = "Launch in Nvidia GeForce NOW"
                $GameAction.Arguments = $PlaActionArguments
                $GameAction.Path = $GeForceNowPath
                $GameAction.WorkingDir = $GeForceNowWorkingPath
                
                # Add Play Action
                if ($Game.OtherActions)
                {
                    $Game.OtherActions.Add($GameAction)
                }
                else
                {
                    # Fix in case game doesn't have other Play Actions
                    $Game.OtherActions = $GameAction
                }

                # Update game in database
                $PlayniteApi.Database.Games.Update($Game)
                $__logger.Info("NVIDIA GeForce NOW Enabler - Play Action added to `"$($Game.name)`"")
                $CounterPlayActionAdded++
            }
        }
    }

    # Show finish dialogue with results
    $Results = "NVIDIA GeForce NOW enabled games in library: $GeForceNowEnabled`n`nAdded `"$featureName`" to $CounterFeatureAdded games`nRemoved `"$featureName`" feature from $CounterFeatureRemoved games"
    if ($AddPlayAction -eq $true)
    {
        $Results += "`n`nPlay Action added to $CounterPlayActionAdded games`nPlay Action removed from $CounterPlayActionRemoved games"
    }
    $PlayniteApi.Dialogs.ShowMessage("$Results", "NVIDIA GeForce NOW Enabler");
}

function Add-Feature
{
    [bool]$AddPlayAction = $false
    Invoke-GeforceNowEnabler -AddPlayAction $AddPlayAction
}
function Add-PlayActionsAndFeature
{
    [bool]$AddPlayAction = $true
    Invoke-GeforceNowEnabler -AddPlayAction $AddPlayAction
}

function Remove-PlayActions
{
    # Set GameDatabase
    $GameDatabase = $PlayniteApi.Database.Games | Where-Object {$_.OtherActions} | Where-Object {$_.Platform.name -eq "PC"}  | Where-Object {$_.source.name -match "(Steam|Epic|Uplay|Origin)"}
    
    # Counters
    $CounterPlayActionRemoved = 0

    foreach ($Game in $GameDatabase) {
        # Check if game already has GeForce NOW Play Action
        $GfnOtherActions = $Game.OtherActions | Where-Object {$_.Arguments -Match "--url-route=`"#\?cmsId=\d+&launchSource=External`""}
        if ($GfnOtherActions.count -ge 1)
        {
            # Remove GeForce NOW Play Actions from game
            foreach ($PlayAction in $GfnOtherActions) {
                $Game.OtherActions.Remove($PlayAction)
                $PlayniteApi.Database.Games.Update($Game)
                $__logger.Info("NVIDIA GeForce NOW Enabler - Play Action removed from `"$($Game.name)`"")
            }
            $CounterPlayActionRemoved++
        }
    }

    # Show finish dialogue with results
    $PlayniteApi.Dialogs.ShowMessage("Play Action removed from $CounterPlayActionRemoved games", "NVIDIA GeForce NOW Enabler");
}

function Set-InstallationStatus
{
    # Set GameDatabase
    $GameDatabase = $PlayniteApi.Database.Games | Where-Object {$_.OtherActions.Arguments -Match "--url-route=`"#\?cmsId=\d+&launchSource=External`""}
    
    # Counters
    $SetAsInstalled = 0

    foreach ($Game in $GameDatabase) {

        if ($game.InstallationStatus -eq 'Uninstalled')
        {
            $game.IsInstalled = $true
            $SetAsInstalled++
            $__logger.Info("NVIDIA GeForce NOW Enabler - Set `"$($Game.name)`" installation status to Installed")
        }
    }

    # Show finish dialogue with results
    $PlayniteApi.Dialogs.ShowMessage("Set $SetAsInstalled games as installed", "NVIDIA GeForce NOW Enabler");
}