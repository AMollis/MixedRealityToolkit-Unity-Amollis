<#
 # Runs the playmode tests in batch mode. This is the same technique as 
 # used by the MRTK PR validation when you do "/azp run mrtk_pr" on github.
 #>
param(
    # Path to your Unity project
    [Parameter(Position=0)]
    [ValidateScript({Test-Path $_ -PathType ‘Container’})]
    [string]
    $projectPath = "$PSScriptRoot/../../",
    # Folder that will contain test results output and logs
    [string]
    [ValidateScript({Test-Path $_ -PathType ‘Container’})]
    $outFolder = "$PSScriptRoot/out/",
    # Path to your Unity Executable
    [ValidateScript({[System.IO.File]::Exists($_) -and $_.EndsWith(".exe") })]
    [string]
    $unityExePath = "C:\Program Files\Unity\Hub\Editor\2018.4.1f1\Editor\Unity.exe"
)
$dateStr = Get-Date -format "yyyy_MM_dd-HHmmss"
if (-not (Test-Path $outFolder))
{
    New-Item -ItemType Directory $outFolder
}
$logPath = "$outFolder\playmode_tests_log-$dateStr.log"
$testResultPath = "$outFolder\playmode_tests_result-$dateStr.xml"

$timer = [System.Diagnostics.Stopwatch]::StartNew()
Write-Output "Starting test run"
Write-Output "Writing test output to $logPath...`n"

# To output unity logs to console, use '-'
# https://docs.unity3d.com/Manual/CommandLineArguments.html
$args = @(
    "-runTests",
    "-testPlatform playmode"
    "-batchmode",
    "-editorTestsResultFile $testResultPath",
    "-logFile $logPath",
    "-projectPath $projectPath"
    )
Write-Output "Running command:"
Write-Output $unityExePath ($args -Join " ")
$handle = Start-Process -FilePath $unityExePath -PassThru -ArgumentList $args

Start-Process powershell -ArgumentList @(
    "-command", 
    "Get-Content $logPath -Wait")

Write-Output "`nOpening new window to view test output..."
Write-Output "Results will be printed here when the test completes"
while (-not $handle.HasExited)
{
    Start-Sleep 3
}

Write-Output "`nTest completed! Results written to $testResultPath"
Write-Output "`nTest results:" -ForegroundColor Cyan
Write-Output "Tests took: $($timer.Elapsed)"

[xml]$cn = Get-Content $testResultPath
$cnx = $cn["test-run"]
Write-Output "passed: $($cnx.passed) failed: $($cnx.failed)"
if ($cnx.failed -gt 0)
{
    Write-Output
    Write-Output "Failed tests:"
    $testcases = $cnx.GetElementsByTagName("test-case")
    foreach ($item in $testcases) {
        if($item.result -ne "Passed")
        {
            Write-Output "$($item.classname)::$($item.name)"
        }
    }
}
