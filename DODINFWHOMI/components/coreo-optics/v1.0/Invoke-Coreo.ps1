#requires -Version 7.6.7

[CmdletBinding()]
param(
    [ValidateSet('Profile', 'SelfTest', 'StoreAudit')]
    [string]$Mode = 'Profile',
    [double]$Sphere = -2.50,
    [double]$Cylinder = -1.25,
    [double]$Axis = 0.0,
    [double[]]$Meridians = @(0.0, 30.0, 45.0, 60.0, 90.0, 135.0, 180.0)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$requiredPowerShellVersion = [version]'7.6.7'
if ($PSVersionTable.PSVersion -ne $requiredPowerShellVersion) {
    throw "This component requires PowerShell $requiredPowerShellVersion exactly; current runtime is $($PSVersionTable.PSVersion)."
}

$sourcePath = Join-Path -Path $PSScriptRoot -ChildPath 'Coreo.Optics.cs'
Add-Type -Path $sourcePath -ErrorAction Stop

$script:InvariantCulture = [Globalization.CultureInfo]::InvariantCulture

function ConvertTo-OpticalDisplayValue {
    param(
        [Parameter(Mandatory)]
        [double]$Value
    )

    $roundedValue = [Math]::Round($Value, 2, [MidpointRounding]::ToEven)
    $formattedValue = $roundedValue.ToString('F2', $script:InvariantCulture).Replace('-', '−')
    "$formattedValue D"
}

function ConvertTo-MeridianDisplayValue {
    param(
        [Parameter(Mandatory)]
        [double]$Value
    )

    $formattedValue = $Value.ToString('0.##', $script:InvariantCulture).Replace('-', '−')
    "$formattedValue°"
}

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

function Write-Profile {
    param(
        [Parameter(Mandatory)]
        [double]$SphereValue,
        [Parameter(Mandatory)]
        [double]$CylinderValue,
        [Parameter(Mandatory)]
        [double]$AxisValue,
        [Parameter(Mandatory)]
        [double[]]$MeridianValues
    )

    if ($MeridianValues.Count -eq 0) {
        throw 'Profile requires at least one meridian.'
    }

    $normalizedAxis = [Coreo.Optics.ToricLensPower]::NormalizeAxis($AxisValue)
    Write-Output ('Sphere: {0} | Cylinder: {1} | Axis: {2}' -f
        (ConvertTo-OpticalDisplayValue -Value $SphereValue),
        (ConvertTo-OpticalDisplayValue -Value $CylinderValue),
        (ConvertTo-MeridianDisplayValue -Value $normalizedAxis))
    Write-Output ('{0,-10} | {1,-16}' -f 'Meridian', 'Effective Power')
    Write-Output ('{0} | {1}' -f ('-' * 10), ('-' * 16))

    foreach ($meridian in $MeridianValues) {
        $power = [Coreo.Optics.ToricLensPower]::GetPowerAtMeridian(
            $SphereValue,
            $CylinderValue,
            $meridian,
            $normalizedAxis)
        $meridianText = ConvertTo-MeridianDisplayValue -Value $meridian
        $powerText = ConvertTo-OpticalDisplayValue -Value $power
        Write-Output ('{0,-10} | {1,-16}' -f $meridianText, $powerText)
    }
}

function Invoke-SelfTest {
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
        $powerWithDefaultAxis = [Coreo.Optics.ToricLensPower]::GetPowerAtMeridian(
            -2.50,
            -1.25,
            $sample.Meridian)
        Assert-Near -Name "Default-axis power at $($sample.Meridian) degrees" `
            -Actual $powerWithDefaultAxis -Expected $sample.Expected

        $powerWithExplicitAxis = [Coreo.Optics.ToricLensPower]::GetPowerAtMeridian(
            -2.50,
            -1.25,
            $sample.Meridian,
            0.0)
        Assert-Near -Name "Explicit-axis power at $($sample.Meridian) degrees" `
            -Actual $powerWithExplicitAxis -Expected $sample.Expected

        $displayValue = ConvertTo-OpticalDisplayValue -Value $powerWithDefaultAxis
        if ($displayValue -cne $sample.Display) {
            throw "Display value at $($sample.Meridian) degrees failed: expected $($sample.Display), received $displayValue."
        }
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

    Assert-Near -Name 'Profile first endpoint' `
        -Actual ([Coreo.Optics.ToricLensPower]::GetPowerAtMeridian(-2.50, -1.25, 0.0)) `
        -Expected -2.50
    Assert-Near -Name 'Profile last endpoint' `
        -Actual ([Coreo.Optics.ToricLensPower]::GetPowerAtMeridian(-2.50, -1.25, 180.0)) `
        -Expected -2.50

    Write-Output 'SelfTest passed: formula, default axis, axis normalization, profile endpoints, and sample display.'
}

function Write-StoreAudit {
    $summaries = [Coreo.Optics.ReadOnlyCertificateStoreAudit]::GetSummary()
    if ($summaries.Length -eq 0) {
        throw 'The certificate-store audit returned no summaries.'
    }

    Write-Output 'Read-only certificate-store summary (counts only).'
    Write-Output ('{0,-15} {1,-20} {2,10}' -f 'Location', 'Store', 'Certificates')
    Write-Output ('{0,-15} {1,-20} {2,10}' -f ('-' * 8), ('-' * 5), ('-' * 11))

    foreach ($summary in $summaries) {
        Write-Output ('{0,-15} {1,-20} {2,10}' -f
            $summary.Location,
            $summary.Store,
            $summary.CertificateCount)
    }
}

switch ($Mode) {
    'Profile' {
        Write-Profile -SphereValue $Sphere -CylinderValue $Cylinder `
            -AxisValue $Axis -MeridianValues $Meridians
    }
    'SelfTest' {
        Invoke-SelfTest
    }
    'StoreAudit' {
        Write-StoreAudit
    }
}
