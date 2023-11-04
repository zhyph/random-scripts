$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$dir = "E:\Media"
$langs = @("por", "pob", "eng")
$files_ext = @{
  "por" = "pt"
  "pob" = "pt"
  "eng" = "en"
}
$lang_map = @{
  "por" = "por"
  "eng" = "eng"
  "pob" = "por"
}

Get-ChildItem -Path $dir -Recurse -File -Exclude *.srt | Where-Object { $_.Extension -match '\.(mkv|mp4|avi|wmv|mov|flv|webm)$' } | ForEach-Object {
  $fileFullName = $_.FullName
  $fileDir = $_.DirectoryName
  $fileBaseName = $_.BaseName
  $subtitles = Get-ChildItem -Path $fileDir -File -Include *.srt -Recurse | Where-Object { $_.BaseName -replace '\.pt|\.en' -eq $fileBaseName }

  if ($subtitles.Count -eq 0) {
    $available_sub_langs = ffprobe -loglevel error -select_streams s -show_entries stream=index:stream_tags=language -of csv=p=0 "$($fileFullName)" | ConvertFrom-Csv -Header Index, Language
    Write-Host "Sub: $($subtitles)`n full: $fileFullName`n dir: $fileDir`n base: $fileBaseName`n available: $($available_sub_langs.Language)`n"

    foreach ($lang in $langs) {
      [bool] $hasSub = $false

      if ($available_sub_langs.Language -contains $lang_map[$lang]) {
        $hasSub = $true
      } 

      if ($hasSub) {
        continue
      }

      if ("$($fileBaseName).$($files_ext[$lang]).srt" -notin $subtitles.Name) { 
        Write-Host "Searching for subtitles for $lang for $fileFullName"
        filebot -script fn:suball "$($fileFullName)" -non-strict --def minAgeDays=4 maxAgeDays=14 --lang $lang --log-file="E:\Media\AMC-log.txt"
      }
    }
  }
}

pwsh -NoProfile $scriptPath\rename_ext.ps1 E:\Media\ por pt
pwsh -NoProfile $scriptPath\rename_ext.ps1 E:\Media\ pob pt-BR
pwsh -NoProfile $scriptPath\rename_ext.ps1 E:\Media\ eng en