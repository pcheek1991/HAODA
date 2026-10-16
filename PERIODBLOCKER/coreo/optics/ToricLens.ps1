#requires -Version 7.6.7
#requires -PSEdition Core

[CmdletBinding()]
param(
    [ValidateSet('Profile', 'SelfTest', 'StoreAudit')]
    [string]$Mode = 'Profile',

    [double]$Sphere = -2.50,
    [double]$Cylinder = -1.25,
    [double]$Axis = 0.0,

    [System.Security.Cryptography.X509Certificates.StoreName]$StoreName = [System.Security.Cryptography.X509Certificates.StoreName]::My,
    [System.Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation = [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$requiredVersion = [version]'7.6.7'
if ($PSVersionTable.PSVersion -ne $requiredVersion) {
    throw "ToricLens requires exactly PowerShell 7.6.7; found $($PSVersionTable.PSVersion)."
}

$powerTypeName = [System.Management.Automation.PSTypeName]::new('Coreo.Optics.ToricLensPower')
if ($null -eq $powerTypeName.Type) {
    $powerSourcePath = Join-Path -Path $PSScriptRoot -ChildPath 'ToricLensPower.cs'
    if (-not (Test-Path -LiteralPath $powerSourcePath -PathType Leaf)) {
        throw "Could not find the ToricLens C# source at $powerSourcePath."
    }

    Add-Type -Path $powerSourcePath -ErrorAction Stop
}

function Format-TwoDecimalNumber {
    param([double]$Value)

    $rounded = [Math]::Round($Value, 2, [System.MidpointRounding]::ToEven)
    $formatted = $rounded.ToString('F2', [System.Globalization.CultureInfo]::InvariantCulture)
    if ($formatted.StartsWith('-', [System.StringComparison]::Ordinal)) {
        return "−$($formatted.Substring(1))"
    }

    return $formatted
}

function Format-ProfilePower {
    param([double]$Value)

    '{0} D' -f (Format-TwoDecimalNumber -Value $Value)
}

function Invoke-ToricLensSelfTest {
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
            [Coreo.Optics.ToricLensPower]::DefaultAxisDegrees
        )

        if ([Math]::Abs($actual - [double]$sampleCase.Expected) -gt 1e-10) {
            throw "ToricLens self-test failed at $($sampleCase.Meridian) degrees: expected $($sampleCase.Expected), got $actual."
        }
    }

    $normalizedAxis = [Coreo.Optics.ToricLensPower]::NormalizeAxis(-30.0)
    if ([Math]::Abs($normalizedAxis - 150.0) -gt 1e-12) {
        throw "ToricLens self-test failed to normalize -30 degrees; got $normalizedAxis."
    }

    Write-Output 'ToricLensPower self-test passed.'
}

function Write-ToricLensProfile {
    $normalizedAxis = [Coreo.Optics.ToricLensPower]::NormalizeAxis($Axis)
    $profileMeridians = @(0, 30, 45, 60, 90, 135, 180)
    $axisText = $normalizedAxis.ToString(
        '0.##',
        [System.Globalization.CultureInfo]::InvariantCulture
    )

    Write-Output (
        'Toric lens profile: Sphere={0} D; Cylinder={1} D; Axis={2}°' -f
        (Format-TwoDecimalNumber -Value $Sphere),
        (Format-TwoDecimalNumber -Value $Cylinder),
        $axisText
    )
    Write-Output 'Meridian | Effective Power'
    Write-Output '-------- | ---------------'

    foreach ($meridian in $profileMeridians) {
        $power = [Coreo.Optics.ToricLensPower]::GetPowerAtMeridian(
            $Sphere,
            $Cylinder,
            [double]$meridian,
            $normalizedAxis
        )
        $meridianText = ([double]$meridian).ToString(
            '0',
            [System.Globalization.CultureInfo]::InvariantCulture
        )

        Write-Output ('{0}° | {1}' -f $meridianText, (Format-ProfilePower -Value $power))
    }
}

function Get-ReadOnlyCertificateStoreSummary {
    param(
        [System.Security.Cryptography.X509Certificates.StoreName]$Name,
        [System.Security.Cryptography.X509Certificates.StoreLocation]$Location
    )

    $store = [System.Security.Cryptography.X509Certificates.X509Store]::new($Name, $Location)
    try {
        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)
        $now = [DateTime]::UtcNow
        $expiryWindow = $now.AddDays(30)
        $certificates = $store.Certificates
        $currentlyValid = 0
        $expired = 0
        $notYetValid = 0
        $expiringWithin30Days = 0

        foreach ($certificate in $certificates) {
            try {
                $notBefore = $certificate.NotBefore.ToUniversalTime()
                $notAfter = $certificate.NotAfter.ToUniversalTime()

                if ($now -lt $notBefore) {
                    $notYetValid++
                }
                elseif ($now -gt $notAfter) {
                    $expired++
                }
                else {
                    $currentlyValid++
                }

                if ($now -ge $notBefore -and $notAfter -le $expiryWindow -and $notAfter -ge $now) {
                    $expiringWithin30Days++
                }
            }
            finally {
                $certificate.Dispose()
            }
        }

        [pscustomobject]@{
            Store               = '{0}\{1}' -f $Location, $Name
            CertificateCount    = $certificates.Count
            CurrentlyValid      = $currentlyValid
            Expired             = $expired
            NotYetValid         = $notYetValid
            ExpiringWithin30Days = $expiringWithin30Days
        }
    }
    finally {
        $store.Dispose()
    }
}

switch ($Mode) {
    'Profile' {
        Write-ToricLensProfile
    }
    'SelfTest' {
        Invoke-ToricLensSelfTest
    }
    'StoreAudit' {
        Get-ReadOnlyCertificateStoreSummary -Name $StoreName -Location $StoreLocation
    }
}
