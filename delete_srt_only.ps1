param (
  [Parameter(Mandatory = $true)]
  [string]$FolderPath
)

# Function to check if a folder has only srt files
function HasOnlySrtFiles($folderPath) {
  $items = Get-ChildItem $folderPath -Force
  foreach ($item in $items) {
    if ($item.PSIsContainer -or $item.Extension -ne ".srt") {
      return $false
    }
  }
  return $true
}

# Function to delete a folder if it has only srt files or is empty
function DeleteFolderIfEmptyOrOnlySrtFiles($folderPath) {
  if (HasOnlySrtFiles $folderPath) {
    Write-Host "Deleting SRT Only: $folderPath"
    Remove-Item $folderPath -Recurse
  }
  else {
    $files = Get-ChildItem $folderPath
    if ($files.Count -eq 0) {
      Write-Host "Deleting Dir: $folderPath"
      Remove-Item $folderPath -Recurse
    }
  }
}

# Function to process a folder and its subfolders
function ProcessFolder($folderPath) {
  $subFolders = Get-ChildItem $folderPath -Directory
  foreach ($subFolder in $subFolders) {
    ProcessFolder $subFolder.FullName
    DeleteFolderIfEmptyOrOnlySrtFiles $subFolder.FullName
  }
}

# Main script
ProcessFolder $FolderPath
DeleteFolderIfEmptyOrOnlySrtFiles $FolderPath
