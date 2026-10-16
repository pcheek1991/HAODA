#requires -Version 5.1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSEdition -ne 'Desktop' -or
    $PSVersionTable.PSVersion.Major -ne 5 -or
    $PSVersionTable.PSVersion.Minor -ne 1) {
    throw "Expected Windows PowerShell 5.1; found $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)."
}

$scriptPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'main_win.ps1'
$scriptText = [System.IO.File]::ReadAllText($scriptPath)
$sourceMatch = [regex]::Match(
    $scriptText,
    '(?ms)^\$cSharpSource = @"\r?\n(?<source>.*?)^"@'
)

if (-not $sourceMatch.Success) {
    throw "Could not find the embedded C# source in $scriptPath."
}

$cSharpSource = $sourceMatch.Groups['source'].Value
Add-Type -TypeDefinition $cSharpSource -Language CSharp -ErrorAction Stop

$payload = 'LuZu-Archivist-Trace'
$encoded = [LuZuEngine.LuZuRot]::ROT13($payload)
if ($encoded -cne 'YhMh-Nepuvivfg-Genpr' -or
    [LuZuEngine.LuZuRot]::EBG13($encoded) -cne $payload) {
    throw 'The embedded C# ROT13 self-test failed.'
}

$sample = 'doubleclick.net;analytics.google.com;example.com;s0.2mdn.net'
$segments = @([LuZuEngine.StringExploder]::SafeExplode($sample, [char]';'))
if ($segments.Count -ne 4 -or ($segments -join ';') -cne $sample) {
    throw 'The embedded C# sample-splitting self-test failed.'
}

Write-Output 'Windows PowerShell 5.1 embedded C# compile and sample checks passed.'
