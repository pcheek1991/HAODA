#requires -Version 7.6.7

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$requiredPowerShellVersion = [version]'7.6.7'
if ($PSVersionTable.PSVersion -ne $requiredPowerShellVersion) {
    throw "These tests require PowerShell $requiredPowerShellVersion exactly; current runtime is $($PSVersionTable.PSVersion)."
}

$componentRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path -Path $componentRoot -ChildPath 'Coreo.Optics.cs'
$entrypointPath = Join-Path -Path $componentRoot -ChildPath 'Invoke-Coreo.ps1'
$sourceText = [IO.File]::ReadAllText($sourcePath)
$storeOpenCalls = [regex]::Matches($sourceText, 'store\.Open\(([^)]*)\)')
if ($storeOpenCalls.Count -ne 1 -or $storeOpenCalls[0].Groups[1].Value -cne 'OpenFlags.ReadOnly') {
    throw 'The certificate-store audit must open stores only with OpenFlags.ReadOnly.'
}
if ($sourceText -match '\bstore\s*\.\s*(?:Add|Remove)\s*\(' -or
    $sourceText -match '\b(?:Import|ImportCertificate)\s*\(') {
    throw 'The certificate-store audit source must not add, remove, or import certificates.'
}
Add-Type -Path $sourcePath -ErrorAction Stop

function Assert-Near {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [double]$Actual,
        [Parameter(Mandatory)]
        [double]$Expected,
        [double]$Tolerance = 1e-12
    )

    if ([Math]::Abs($Actual - $Expected) -gt $Tolerance) {
        throw "$Name failed: expected $Expected, received $Actual (tolerance $Tolerance)."
    }
}

$sampleRows = @(
    [pscustomobject]@{ Meridian = 0.0; Expected = -2.50; Display = '−2.50 D' }
    [pscustomobject]@{ Meridian = 30.0; Expected = -2.8125; Display = '−2.81 D' }
    [pscustomobject]@{ Meridian = 45.0; Expected = -3.125; Display = '−3.12 D' }
    [pscustomobject]@{ Meridian = 60.0; Expected = -3.4375; Display = '−3.44 D' }
    [pscustomobject]@{ Meridian = 90.0; Expected = -3.75; Display = '−3.75 D' }
    [pscustomobject]@{ Meridian = 135.0; Expected = -3.125; Display = '−3.12 D' }
    [pscustomobject]@{ Meridian = 180.0; Expected = -2.50; Display = '−2.50 D' }
)

foreach ($sample in $sampleRows) {
    $power = [Coreo.Optics.ToricLensPower]::GetPowerAtMeridian(
        -2.50,
        -1.25,
        $sample.Meridian)
    Assert-Near -Name "Default-axis power at $($sample.Meridian) degrees" `
        -Actual $power -Expected $sample.Expected

    $explicitAxisPower = [Coreo.Optics.ToricLensPower]::GetPowerAtMeridian(
        -2.50,
        -1.25,
        $sample.Meridian,
        0.0)
    Assert-Near -Name "Explicit-axis power at $($sample.Meridian) degrees" `
        -Actual $explicitAxisPower -Expected $sample.Expected
}

$axisCases = @(
    [pscustomobject]@{ Input = -360.0; Expected = 0.0 }
    [pscustomobject]@{ Input = -181.0; Expected = 179.0 }
    [pscustomobject]@{ Input = -180.0; Expected = 0.0 }
    [pscustomobject]@{ Input = -[double]::Epsilon; Expected = [Math]::BitDecrement(180.0) }
    [pscustomobject]@{ Input = -45.0; Expected = 135.0 }
    [pscustomobject]@{ Input = 0.0; Expected = 0.0 }
    [pscustomobject]@{ Input = 180.0; Expected = 0.0 }
    [pscustomobject]@{ Input = 181.0; Expected = 1.0 }
    [pscustomobject]@{ Input = 270.0; Expected = 90.0 }
    [pscustomobject]@{ Input = 360.0; Expected = 0.0 }
)

foreach ($axisCase in $axisCases) {
    $normalizedAxis = [Coreo.Optics.ToricLensPower]::NormalizeAxis($axisCase.Input)
    Assert-Near -Name "Axis normalization for $($axisCase.Input) degrees" `
        -Actual $normalizedAxis -Expected $axisCase.Expected
    if ($normalizedAxis -lt 0.0 -or $normalizedAxis -ge 180.0) {
        throw "Normalized axis is outside [0, 180): $normalizedAxis."
    }
    if ($axisCase.Input -eq -[double]::Epsilon -and
        $normalizedAxis -ne [Math]::BitDecrement(180.0)) {
        throw "The smallest negative axis must normalize to the greatest representable value below 180: $normalizedAxis."
    }
}

$firstEndpoint = [Coreo.Optics.ToricLensPower]::GetPowerAtMeridian(-2.50, -1.25, 0.0)
$lastEndpoint = [Coreo.Optics.ToricLensPower]::GetPowerAtMeridian(-2.50, -1.25, 180.0)
Assert-Near -Name 'Profile first endpoint' -Actual $firstEndpoint -Expected -2.50
Assert-Near -Name 'Profile last endpoint' -Actual $lastEndpoint -Expected -2.50

$pwshPath = Join-Path -Path $PSHOME -ChildPath 'pwsh.exe'
if (-not (Test-Path -LiteralPath $pwshPath -PathType Leaf)) {
    throw "Could not find the PowerShell executable beside PSHOME: $pwshPath."
}

$profileOutput = @(& $pwshPath -NoLogo -NoProfile -File $entrypointPath -Mode Profile 2>&1)
$profileExitCode = $LASTEXITCODE
if ($profileExitCode -ne 0) {
    throw "Profile mode exited with code $profileExitCode.`n$($profileOutput -join [Environment]::NewLine)"
}

$expectedHeader = '{0,-10} | {1,-16}' -f 'Meridian', 'Effective Power'
$expectedRows = foreach ($sample in $sampleRows) {
    $meridianText = $sample.Meridian.ToString('0.##', [Globalization.CultureInfo]::InvariantCulture) + '°'
    '{0,-10} | {1,-16}' -f $meridianText, $sample.Display
}

$expectedProfileOutput = @(
    'Sphere: −2.50 D | Cylinder: −1.25 D | Axis: 0°'
    $expectedHeader
    '{0} | {1}' -f ('-' * 10), ('-' * 16)
    $expectedRows
)
if ($profileOutput.Count -ne $expectedProfileOutput.Count) {
    throw "Profile output had $($profileOutput.Count) lines; expected $($expectedProfileOutput.Count)."
}
for ($lineIndex = 0; $lineIndex -lt $expectedProfileOutput.Count; $lineIndex++) {
    if ($profileOutput[$lineIndex] -cne $expectedProfileOutput[$lineIndex]) {
        throw "Profile line $lineIndex failed: expected [$($expectedProfileOutput[$lineIndex])], received [$($profileOutput[$lineIndex])]."
    }
}

$selfTestOutput = @(& $pwshPath -NoLogo -NoProfile -File $entrypointPath -Mode SelfTest 2>&1)
$selfTestExitCode = $LASTEXITCODE
if ($selfTestExitCode -ne 0) {
    throw "SelfTest mode exited with code $selfTestExitCode.`n$($selfTestOutput -join [Environment]::NewLine)"
}

if ($selfTestOutput -cnotcontains 'SelfTest passed: formula, default axis, axis normalization, profile endpoints, and sample display.') {
    throw "SelfTest mode did not report success.`n$($selfTestOutput -join [Environment]::NewLine)"
}

Write-Output 'All Coreo optics tests passed (raw formula values, axis normalization, endpoints, sample profile, and self-test mode).'
