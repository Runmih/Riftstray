param(
    [string]$GodotPath = "C:\Users\fprud\AppData\Local\Temp\riftstray-godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe",
    [string]$ProjectPath = "D:\Riftstray",
    [string]$LogDirectory = "D:\Riftstray\tests\logs\full"
)

$ErrorActionPreference = "Stop"
$suiteFiles = @(
    "foundation_tests.gd",
	"g3b3_tests.gd",
    "combat_progression_tests.gd",
    "tactical_tests.gd",
    "r1b_tests.gd",
    "mouse_input_tests.gd",
    "r3_tests.gd",
    "r4_tests.gd",
    "r5_tests.gd",
    "r6a_tests.gd",
    "r6b_tests.gd"
)

New-Item -ItemType Directory -Force -Path $LogDirectory | Out-Null
$failed = $false
foreach ($suiteFile in $suiteFiles) {
    $suiteName = [System.IO.Path]::GetFileNameWithoutExtension($suiteFile)
    $logPath = Join-Path $LogDirectory "$suiteName.log"
    $stdoutPath = Join-Path $LogDirectory "$suiteName.stdout.tmp"
    $stderrPath = Join-Path $LogDirectory "$suiteName.stderr.tmp"
    $process = Start-Process -FilePath $GodotPath -ArgumentList @("--headless", "--path", $ProjectPath, "--script", "res://tests/$suiteFile") -NoNewWindow -Wait -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
    $output = ((Get-Content -LiteralPath $stdoutPath -Raw) + (Get-Content -LiteralPath $stderrPath -Raw))
    $exitCode = $process.ExitCode
    Remove-Item -LiteralPath $stdoutPath, $stderrPath
    Set-Content -LiteralPath $logPath -Value $output -Encoding utf8
    $hasScriptFailure = $output -match "(?m)^(SCRIPT ERROR|ERROR: FAIL:|FAIL:)"
    $summary = [regex]::Match($output, "(?mi)^.*(?:TESTS|checks).*?$").Value.Trim()
    if ($exitCode -ne 0 -or $hasScriptFailure -or [string]::IsNullOrWhiteSpace($summary)) {
        $failed = $true
        Write-Output "$suiteName : FAIL (exit $exitCode) | $logPath"
    } else {
        Write-Output "$suiteName : PASS | $summary | $logPath"
    }
}

if ($failed) {
    exit 1
}
exit 0
