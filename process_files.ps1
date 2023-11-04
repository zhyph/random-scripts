# The script accepts three parameters: label, title, and dir.
# These parameters can be passed when calling the script in the following way:
# .\process_files.ps1 -label "exampleLabel" -title "exampleTitle" -dir "C:\exampleDirectory"

param (
    [string]$label,
    [string]$title,
    [string]$dir
)

$languages = @("pt", "en")

$langs_to_search = @{
    "en" = @("en")
    "pt" = @("por", "pob")
}

$lang_map = @{
    "en" = @("eng", "en", "English")
    "pt" = @("por", "pt", "Portuguese")
}

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$envPath = Join-Path $scriptPath ".env"

Get-Content $envPath | ForEach-Object {
    $name, $value = $_.split('=')
    if ([string]::IsNullOrWhiteSpace($name) || $name.Contains('#')) {
        continue
    }
    Set-Content env:\$name $value
}

if ([string]::IsNullOrEmpty($label) -or [string]::IsNullOrEmpty($title) -or [string]::IsNullOrEmpty($dir)) {
    Write-Host "Usage: $PSCommandPath -label <label> -title <title> -dir <directory>"
    exit 1
}

Write-Host "Parameters:"
Write-Host "label: $label"
Write-Host "title: $title"
Write-Host "dir: $dir"

if ($label -eq "Games") {
    Write-Host "Label is 'Games', exiting..."
    exit 0
}

$logFilePath = "E:\Media\Script-log.txt"

# Function to log messages
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string] $LogMessage
    )

    $mutex = New-Object System.Threading.Mutex($false, "logFileMutex")

    try {
        $mutex.WaitOne()

        $logEntry = "$LogMessage`n"
        $retryCount = 0
        while ($true) {
            try {
                Add-Content -Path $logFilePath -Value $logEntry
                break
            }
            catch {
                if ($retryCount -ge 5) { throw }
                Start-Sleep -Seconds 2
                $retryCount++
            }
        }
    }
    finally {
        $mutex.ReleaseMutex()
    }
}

try {    
    filebot -script fn:amc --output "E:\Media" --action hardlink -non-strict --def skipExtract=n --def deleteAfterExtract=n --def excludeList="E:\Media\amc.txt" --def extractFolder="E:\Torrents\Extracted" --def clean=y --def animeDB=TheTVDB movieDB=TheMovieDB seriesDB=TheTVDB musicDB=ID3 --log-file="E:\Media\AMC-log.txt" --conflict override --def seriesFormat="{anime ? 'Anime' : 'TV Shows'}/{~plex.id}" movieFormat="{anime ? 'Anime Movies' : 'Movies'}/{~plex.id}" --def ut_label=$label ut_title=$title ut_kind=multi ut_dir="$dir" --def plex=localhost:32400:$env:PLEX_TOKEN

    $mediaFiles = Get-ChildItem "E:\Media\" -Recurse -File -Include "*.mp4", "*.mkv", "*.mov", "*.wmv", "*.avi", "*.flv", "*.avchd"
    
    $ignoreList = Get-Content "E:\Media\sub-ignore.txt"

    $directoriesForProcessing = $mediaFiles | Where-Object { $ignoreList -notcontains $_.FullName }

    foreach ($file in $directoriesForProcessing) {
        $fileFullName = $file.FullName
        
        $ignoreList = Get-Content "E:\Media\sub-ignore.txt"
        if ($ignoreList -contains $fileFullName) {
            continue
        }
        
        $available_sub_langs = ffprobe -loglevel error -select_streams s -show_entries stream=index:stream_tags=language -of csv=p=0 "$($fileFullName)" | ConvertFrom-Csv -Header Index, Language
        
        Add-Content -Path "E:\Media\sub-ignore.txt" -Value "$($fileFullName)"
        $srtFiles = (Get-ChildItem $file.DirectoryName -File -Include "*.srt" -Recurse).Name

        foreach ($lang in $languages) {
            [bool] $hasSub = $false

            foreach ($mapped_lang in $lang_map[$lang]) { 
                if ($available_sub_langs.Language -contains $mapped_lang) {
                    $hasSub = $true
                } 
            }

            if ($hasSub) {
                continue
            }
           
            if ("$($file.BaseName).$lang.srt" -notin $srtFiles) { 
                Write-Host "Searching for subtitles for $lang for $fileFullName"
                foreach ($sub_lang in $langs_to_search[$lang]) {
                    filebot -script fn:suball "$($fileFullName)" -non-strict --def maxAgeDays=1 --lang $sub_lang --log-file="E:\Media\AMC-log.txt"
                }
            }
        }
    }

    pwsh -NoProfile $scriptPath\rename_ext.ps1 E:\Media\ por pt
    pwsh -NoProfile $scriptPath\rename_ext.ps1 E:\Media\ pob "pt-BR"
}
catch {
    Write-Log "Error: $_"
    Write-Log "----------------------------------------"
}


