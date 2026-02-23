### Scans a directory tree and reports lengths of full paths (useful for finding overly long paths)

# Output the length of all files and folders in the given directory path.
[CmdletBinding()]
param
(
    [Parameter(HelpMessage = 'Only paths this length or longer will be included in the results. Set this to 260 to find problematic paths in Windows.')]
    [int] $MinimumPathLengthsToShow = 0,

    [Parameter(HelpMessage = 'If the results should be written to the console or not. Can be slow if there are many results.')]
    [bool] $WriteResultsToConsole = $false,

    [Parameter(HelpMessage = 'If the results should be shown in a Grid View or not once the scanning completes.')]
    [bool] $WriteResultsToGridView = $true,

    [Parameter(HelpMessage = 'If the results should be written to a file or not.')]
    [bool] $WriteResultsToFile = $true,

    [Parameter(HelpMessage = 'The file path to write the results to when $WriteResultsToFile is true.')]
    [string] $ResultsFilePath = 'C:\Temp\PathLengths.txt'
)

# Prompt for directory to scan
$DirectoryPathToScan = Read-Host "Please enter directory to scan"

# Prompt for minimum path length Only paths this length or longer will be included in the results. Set this to 260 to find problematic paths in Windows
$MinimumPathLengthsToShow = Read-Host "Please enter minimum path lenght to show, default = 0"

# Display the time that this script started running.
[datetime] $startTime = Get-Date
Write-Verbose "Starting script at '$startTime'." -Verbose

# Ensure output directory exists
[string] $resultsFileDirectoryPath = Split-Path $ResultsFilePath -Parent
if (!(Test-Path $resultsFileDirectoryPath)) { New-Item $resultsFileDirectoryPath -ItemType Directory }

# Open a new file stream (nice and fast) to write all the paths and their lengths to it.
if ($WriteResultsToFile) { $fileStream = New-Object System.IO.StreamWriter($ResultsFilePath, $false) }

$filePathsAndLengths = [System.Collections.ArrayList]::new()

# Get all file and directory paths and write them if applicable.
Get-ChildItem -Path $DirectoryPathToScan -Recurse -Force |
    Select-Object -Property @{Name = "FullNameLength"; Expression = { ($_.FullName.Length) } }, FullName |
    Sort-Object -Property FullNameLength -Descending |
    ForEach-Object {

    $filePath = $_.FullName
    $length = $_.FullNameLength

    # If this path is long enough, add it to the results.
    if ($length -ge $MinimumPathLengthsToShow)
    {
        [string] $lineOutput = "$length : $filePath"

        if ($WriteResultsToConsole) { Write-Output $lineOutput }

        if ($WriteResultsToFile) { $fileStream.WriteLine($lineOutput) }

        $filePathsAndLengths.Add($_) > $null
    }
}

if ($WriteResultsToFile) { $fileStream.Close() }

# Display the time that this script finished running, and how long it took to run.
[datetime] $finishTime = Get-Date
[timespan] $elapsedTime = $finishTime - $startTime
Write-Verbose "Finished script at '$finishTime'. Took '$elapsedTime' to run. Results saved to C:\Temp\PathLengths.txt" -Verbose

if ($WriteResultsToGridView) { $filePathsAndLengths | Out-GridView -Wait -Title "Paths under '$DirectoryPathToScan' longer than '$MinimumPathLengthsToShow'." }

Read-Host = "Press enter to exit"