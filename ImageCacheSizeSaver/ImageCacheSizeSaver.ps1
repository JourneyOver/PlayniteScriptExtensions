function global:GetMainMenuItems
{
    param($menuArgs)

    $menuItem1 = New-Object Playnite.SDK.Plugins.ScriptMainMenuItem
    $menuItem1.Description = "Process Images in Cache"
    $menuItem1.FunctionName = "Invoke-ImageCacheSizeSaver"
    $menuItem1.MenuSection = "@Image Cache Size Saver"

    return $menuItem1
}

function Invoke-ImageCacheSizeSaver
{
    # Set images cache path
    if ($PlayniteApi.Paths.IsPortable -eq $true)
    {
        $__logger.Info("Image Cache Size Saver - Playnite is Portable.")
        $PathCacheDirectory = Join-Path -Path $PlayniteApi.Paths.ApplicationPath -ChildPath "cache\images\*"
    }
    else
    {
        $__logger.Info("Image Cache Size Saver - Playnite is Installed.")
        $PathCacheDirectory = Join-Path -Path $env:APPDATA -ChildPath "Playnite\cache\images\*"
    }

    # Try to get magick.exe path via registry
    $Key = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
    $RegSubKey =  $Key.OpenSubKey("Software\ImageMagick\Current")
    if ($RegSubKey)
    {
        $RegInstallDir = $RegSubKey.GetValue("BinPath")
        if ($RegInstallDir)
        {
            $MagickExecutable = Join-Path -Path $RegInstallDir -ChildPath 'magick.exe'
            if (Test-Path $MagickExecutable)
            {
                $MagickExecutablePath = $MagickExecutable
                $__logger.Info("Image Cache Size Saver - Found executable Path via registry in `"$MagickExecutablePath`".")
            }
        }
    }

    if ($null -eq $MagickExecutablePath)
    {
        # Set Magick Executable Path via user Input
        $MagickConfigPath = Join-Path -Path $CurrentExtensionDataPath -ChildPath 'ConfigMagicPath.ini'
        if (Test-Path $MagickConfigPath)
        {
            $MagickExecutablePath = [System.IO.File]::ReadAllLines($MagickConfigPath)
        }
        else
        {
            $PlayniteApi.Dialogs.ShowMessage("Select ImageMagick executable", "Image Cache Size Saver")
            $MagickExecutablePath = $PlayniteApi.Dialogs.SelectFile("magick|magick.exe")
            if (!$MagickExecutablePath)
            {
                exit
            }
            [System.IO.File]::WriteAllLines($MagickConfigPath, $MagickExecutablePath)
            $__logger.Info("Image Cache Size Saver - Saved executable Path via user input in `"$MagickExecutablePath`".")
            $PlayniteApi.Dialogs.ShowMessage("Magick executable path saved", "Image Cache Size Saver")
        }

        if (!(Test-Path $MagickExecutablePath))
        {
            [System.IO.File]::Delete($MagickConfigPath)
            $__logger.Info("Image Cache Size Saver - Executable not found in user configured path `"$MagickExecutablePath`".")
            $PlayniteApi.Dialogs.ShowMessage("Magick executable not found in `"$MagickExecutablePath`". Please run the extension again to configure it to the correct location.", "Image Cache Size Saver")
            exit
        }
    }

    # Set arrays for processed games and image extensions
    $PreviouslyProcessedPath = Join-Path -Path $CurrentExtensionDataPath -ChildPath 'ImageCacheSizeSaverList.txt'
    if (Test-Path $PreviouslyProcessedPath)
    {
        [System.Collections.Generic.List[string]]$PreviouslyProcessedList = @([System.IO.File]::ReadAllLines($PreviouslyProcessedPath))
        $__logger.Info("Image Cache Size Saver - Found existing processed list")

    }
    else
    {
        [System.Collections.Generic.List[string]]$PreviouslyProcessedList = @()
        $__logger.Info("Image Cache Size Saver - Did not find existing processed list")
    }
    $ImageExtensions= @(
        "*.jpg",
        "*.png",
        "*.gif"
    )

    # Set Counters
    $ProcessedError = 0
    $ProcessedLessSize = 0

    # Set images to be processed and get current cache size
    $ImagesAll = Get-ChildItem -path $PathCacheDirectory -Include $ImageExtensions
    $ImagesToProcess = (Get-ChildItem -path $ImagesAll -Exclude $PreviouslyProcessedList).FullName
    [string]$ImagesSizeBefore = "{0:N2}" -f (($ImagesAll | Measure-Object -Sum Length).Sum / 1MB)
    $ImageTempPath = Join-Path -Path $env:temp -ChildPath 'ImageCacheSizeSaver.tmp'
    
    foreach ($ImageSourcePath in $ImagesToProcess) {
        try {
            # Process Image with ImageMagick. Try to delete temp image for safety.
            [System.IO.File]::Delete($ImageTempPath)
            & "$MagickExecutablePath" "$ImageSourcePath[0]" $ImageTempPath

            # Overwrite original image if it's bigger than processed image
            if ( ((Get-Item $ImageTempPath).length) -lt ((Get-Item $ImageSourcePath).length) )
            {
                [System.IO.File]::Delete($ImageSourcePath)
                [System.IO.File]::Move($ImageTempPath, $ImageSourcePath)
                $ProcessedLessSize++
            }
            else
            {
                [System.IO.File]::Delete($ImageTempPath)
            }

            # Add to processed list
            $ImageFileName = [System.IO.Path]::GetFileName($ImageSourcePath)
            $PreviouslyProcessedList.Add($ImageFileName)
        } catch {
            $ErrorMessage = $_.Exception.Message
            $__logger.Error("Image Cache Size Saver - `"$ImageSourcePath`" image couldn't be processed - Error: $ErrorMessage")
            $ProcessedError++
        }
    }
    
    # Write new process list, calculate Image Cache Size after processing and show results
    [System.IO.File]::WriteAllLines($PreviouslyProcessedPath, $PreviouslyProcessedList)
    [string]$ImagesSizeAfter = "{0:N2}" -f ((Get-ChildItem -path $PathCacheDirectory -Include $ImageExtensions | Measure-Object -Sum Length).Sum / 1MB)
    $__logger.Info("Image Cache Size Saver - Image processing finished. Images Processed: $($ImagesToProcess.count). Images that had size reduced: $ProcessedLessSize. Errors: $ProcessedError. Image Cache Size Before: $ImagesSizeBefore MB. Image Cache Size After: $ImagesSizeAfter MB")
    $PlayniteApi.Dialogs.ShowMessage("Image processing finished. Results:`n`nImages Processed: $($ImagesToProcess.count)`n`nImages that had size reduced: $ProcessedLessSize`nErrors: $ProcessedError`n`nImage Cache Size Before: $ImagesSizeBefore MB`nImage Cache Size After: $ImagesSizeAfter MB", "Image Cache Size Saver")
}