# Check if all 3 arguments are provided
if ($args.Count -ne 3) {
  Write-Host "Usage: $PSCommandPath <directory> <old_extension> <new_extension>"
  exit 1
}

# Assign the arguments to variables
$dir = $args[0]
$old_ext = $args[1]
$new_ext = $args[2]

# Write-Output "Renaming files with extension $old_ext to $new_ext in directory $dir"

Get-ChildItem -Path $dir -Recurse -File | Where-Object { $_.FullName -like "*$old_ext*" } | ForEach-Object {
  # Replace the old extension with the new extension
  $new_file = $_.FullName -replace $old_ext, $new_ext
  # Check if a file with the new extension already exists
  if (Test-Path $new_file) {
    Write-Output "File with new extension already exists: $new_file"
    # Remove the file with the old extension
    Remove-Item $_.FullName
  }
  else {
    Write-Output "Renaming $_ to $new_file"
    # Rename the file
    Rename-Item $_.FullName $new_file
  }
}
