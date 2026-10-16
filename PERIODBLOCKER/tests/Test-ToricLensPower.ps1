#requires -Version 7.6.7
#requires -PSEdition Core

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$requiredVersion = [version]'7.6.7'
if ($PSVersionTable.PSVersion -ne $requiredVersion) {
    throw "ToricLens tests require exactly PowerShell 7.6.7; found $($PSVersionTable.PSVersion)."
}

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$componentPath = Join-Path -Path $repositoryRoot -ChildPath 'coreo\optics\ToricLens.ps1'
$powerSourcePath = Join-Path -Path $repositoryRoot -ChildPath 'coreo\optics\ToricLensPower.cs'
Add-Type -Path $powerSourcePath -ErrorAction Stop

function Assert-Near {
    param(
        [string]$Name,
        [double]$Actual,
        [double]$Expected,
        [double]$Tolerance = 1e-10
    )

    if ([Math]::Abs($Actual - $Expected) -gt $Tolerance) {
        throw "$Name expected $Expected, got $Actual (tolerance $Tolerance)."
    }
}

$defaultAxis = [Coreo.Optics.ToricLensPower]::DefaultAxisDegrees
Assert-Near -Name 'Default axis' -Actual $defaultAxis -Expected 0.0 -Tolerance 1e-12

$sampleCases = @(
    [pscustomobject]@{ Meridian = 0.0; Expected = -2.50 },
    [pscustomobject]@{ Meridian = 30.0; Expected = -2.8125 },
    [pscustomobject]@{ Meridian = 45.0; Expected = -3.125 },
    [pscustomobject]@{ Meridian = 60.0; Expected = -3.4375 },
    [pscustomobject]@{ Meridian = 90.0; Expected = -3.75 },
    [pscustomobject]@{ Meridian = 135.0; Expected = -3.125 },
    [pscustomobject]@{ Meridian = 180.0; Expected = -2.50 }
)

foreach ($sampleCase in $sampleCases) {
    $actual = [Coreo.Optics.ToricLensPower]::GetPowerAtMeridian(
        -2.50,
        -1.25,
        [double]$sampleCase.Meridian,
        0.0
    )
    Assert-Near -Name "Power at $($sampleCase.Meridian) degrees" -Actual $actual -Expected $sampleCase.Expected
}

$onAxisPower = [Coreo.Optics.ToricLensPower]::GetPowerAtMeridian(-2.50, -1.25, 45.0, 45.0)
$perpendicularPower = [Coreo.Optics.ToricLensPower]::GetPowerAtMeridian(-2.50, -1.25, 135.0, 45.0)
Assert-Near -Name 'Power along a non-zero axis' -Actual $onAxisPower -Expected -2.50
Assert-Near -Name 'Power perpendicular to a non-zero axis' -Actual $perpendicularPower -Expected -3.75

$axisCases = @(
    [pscustomobject]@{ Input = -360.0; Expected = 0.0 },
    [pscustomobject]@{ Input = -30.0; Expected = 150.0 },
    [pscustomobject]@{ Input = 0.0; Expected = 0.0 },
    [pscustomobject]@{ Input = 180.0; Expected = 0.0 },
    [pscustomobject]@{ Input = 181.0; Expected = 1.0 },
    [pscustomobject]@{ Input = 540.0; Expected = 0.0 }
)

foreach ($axisCase in $axisCases) {
    $actual = [Coreo.Optics.ToricLensPower]::NormalizeAxis([double]$axisCase.Input)
    Assert-Near -Name "Axis normalization for $($axisCase.Input) degrees" -Actual $actual -Expected $axisCase.Expected -Tolerance 1e-12
    if ($actual -lt 0.0 -or $actual -ge 180.0) {
        throw "Normalized axis $actual is outside [0, 180)."
    }
}

$negativeEpsilon = -[double]::Epsilon
$almost180 = [Coreo.Optics.ToricLensPower]::NormalizeAxis($negativeEpsilon)
if ($almost180 -lt 0.0 -or $almost180 -ge 180.0) {
    throw "A tiny negative axis normalized outside [0, 180): $almost180."
}

$startPower = [Coreo.Optics.ToricLensPower]::GetPowerAtMeridian(-2.50, -1.25, 0.0, 0.0)
$endPower = [Coreo.Optics.ToricLensPower]::GetPowerAtMeridian(-2.50, -1.25, 180.0, 0.0)
Assert-Near -Name 'Profile endpoint equivalence' -Actual $endPower -Expected $startPower

$pwshPath = Join-Path -Path $PSHOME -ChildPath 'pwsh.exe'
$profileOutput = & $pwshPath -NoLogo -NoProfile -File $componentPath -Mode Profile
if ($LASTEXITCODE -ne 0) {
    throw "ToricLens profile mode exited with code $LASTEXITCODE."
}

if ($profileOutput -notcontains 'Meridian | Effective Power') {
    throw 'ToricLens profile output did not use the expected column headings.'
}

$expectedProfileRows = @(
    '0° | −2.50 D',
    '30° | −2.81 D',
    '45° | −3.12 D',
    '60° | −3.44 D',
    '90° | −3.75 D',
    '135° | −3.12 D',
    '180° | −2.50 D'
)

foreach ($expectedRow in $expectedProfileRows) {
    if ($profileOutput -notcontains $expectedRow) {
        throw "ToricLens profile output did not contain the expected sample row: '$expectedRow'."
    }
}

$selfTestOutput = & $pwshPath -NoLogo -NoProfile -File $componentPath -Mode SelfTest
if ($LASTEXITCODE -ne 0 -or ($selfTestOutput -join [Environment]::NewLine) -notmatch 'self-test passed') {
    throw 'ToricLens self-test mode did not report success.'
}

Write-Output 'ToricLens formula, axis normalization, profile endpoints, sample output, and self-test checks passed.'
