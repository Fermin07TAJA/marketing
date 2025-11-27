$base    = "C:\Users\Chickenfish\Downloads\Consumers"
$renamed = Join-Path $base "Renamed"
$state   = Join-Path $base "date_state.txt"

if (-not (Test-Path $renamed)) {
    New-Item -ItemType Directory -Path $renamed | Out-Null
}

# Initialize starting point if needed: Jan 2019
if (-not (Test-Path $state)) {
    "2019 01" | Set-Content -Path $state -Encoding ASCII
}

# FileSystemWatcher for new CSVs
$fsw = New-Object System.IO.FileSystemWatcher
$fsw.Path                  = $base
$fsw.Filter                = "*.csv"
$fsw.IncludeSubdirectories = $false
$fsw.EnableRaisingEvents   = $true

Register-ObjectEvent -InputObject $fsw -EventName Created -SourceIdentifier CsvCreated -Action {
    param($Sender, $EventArgs)

    $path    = $EventArgs.FullPath
    $base    = "C:\Users\Chickenfish\Downloads\Consumers"
    $renamed = Join-Path $base "Renamed"
    $state   = Join-Path $base "date_state.txt"

    # Wait until the file is no longer locked by the browser
    while ($true) {
        try {
            $stream = [System.IO.File]::Open($path, 'Open', 'Read', 'ReadWrite')
            $stream.Close()
            break
        } catch {
            Start-Sleep -Milliseconds 200
        }
    }

    # Read current "next" year and month
    $line  = Get-Content -Path $state -Raw
    $parts = $line -split '\s+'
    $year  = [int]$parts[0]
    $month = [int]$parts[1]

    $yy = $year % 100
    $mm = "{0:D2}" -f $month
    $newName = "{0:D2}-{1}.csv" -f $yy, $mm

    $dest = Join-Path $renamed $newName

    Move-Item -LiteralPath $path -Destination $dest

    # Increment month
    $month++
    if ($month -gt 12) {
        $month = 1
        $year++
    }

    "{0} {1:D2}" -f $year, $month | Set-Content -Path $state -Encoding ASCII

    Write-Host "Moved $path -> $dest"
}

Write-Host "Watching $base for new CSV files. Press Ctrl+C to stop."

while ($true) {
    Start-Sleep -Seconds 5
}
