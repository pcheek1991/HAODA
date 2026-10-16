#requires -Version 7.6.6
#requires -PSEdition Core
<#
.SYNOPSIS
  Standalone public certificate-to-atomic-hex companion for Lu Zu Obelisk.
.DESCRIPTION
  Accepts drag-and-drop certificate path as first argument or -CertificatePath.
  Supports DER or PEM X.509 (.cer/.crt/.der/.pem) and CMS PKCS#7 (.p7b/.p7c).
  Outputs one @CERT ... @END block per unique public certificate.
  No installation, network, script editing, private-key processing, or elevated rights.
  Paste the emitted blocks inside $EmbeddedCertificateHex in main.ps1,
  BEFORE its closing delimiter ('@ at the start of a line).
.EXAMPLE
  pwsh -NoProfile -File .\companion.ps1 -CertificatePath C:\Certificates\example.cer -Label 'Example'
.EXAMPLE
  pwsh -NoProfile -File .\companion.ps1 'C:\Certificates\example.p7b' -Group UserSupplied -OutputPath C:\Certificates\new-certs-hex.txt
#>
[CmdletBinding()]
param(
    [Parameter(Position=0,Mandatory=$true)]
    [string]$CertificatePath,
    [string]$Label,
    [ValidatePattern('^[A-Za-z][A-Za-z0-9_-]{0,63}$')]
    [string]$Group='UserSupplied',
    [string]$OutputPath,
    [switch]$ConsoleOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Get-PublicCertificateDer([string]$FileName) {
    $info=Get-Item -LiteralPath $FileName -ErrorAction Stop
    if ($info.PSIsContainer) { throw 'Expected a certificate file, not a directory.' }
    if ($info.Length -le 0 -or $info.Length -gt 8MB) { throw 'Input must be 1 byte through 8 MiB.' }
    $extension=[IO.Path]::GetExtension($info.Name).ToLowerInvariant()
    if ($extension -notin '.cer','.crt','.der','.pem','.p7b','.p7c') {
        throw 'Only public X.509 and PKCS#7 certificate containers are supported; PFX/P12 keys are never accepted.'
    }
    [byte[]]$data=[IO.File]::ReadAllBytes($info.FullName)
    $items=[System.Collections.Generic.List[byte[]]]::new()
    if ($extension -in '.p7b','.p7c') {
        if ([Text.Encoding]::ASCII.GetString($data,0,[Math]::Min(100,$data.Length)).Contains('-----BEGIN')) {
            $text=[Text.Encoding]::ASCII.GetString($data)
            $pem=[regex]::Match($text,'-----BEGIN (?:PKCS7|CMS)-----\s*([A-Za-z0-9+/=\s]+)-----END (?:PKCS7|CMS)-----')
            if (-not $pem.Success) { throw 'Expected PKCS7/CMS PEM boundaries.' }
            $data=[Convert]::FromBase64String(($pem.Groups[1].Value -replace '\s',''))
        }
        $message=[Security.Cryptography.Pkcs.SignedCms]::new()
        $message.Decode($data)
        if ($message.Certificates.Count -eq 0) { throw 'The PKCS#7 container has no embedded certificates.' }
        foreach($certificate in $message.Certificates) {
            try { $items.Add($certificate.RawData) }
            finally { $certificate.Dispose() }
        }
    } else {
        $text=[Text.Encoding]::ASCII.GetString($data)
        $pem=[regex]::Matches($text,'-----BEGIN CERTIFICATE-----\s*([A-Za-z0-9+/=\s]+)-----END CERTIFICATE-----')
        if ($pem.Count -gt 0) {
            foreach($match in $pem) {
                [byte[]]$der=[Convert]::FromBase64String(($match.Groups[1].Value -replace '\s',''))
                $items.Add($der)
            }
        } else {
            $items.Add($data)
        }
    }
    return $items.ToArray()
}

function ConvertTo-CatalogBlock([byte[]]$Der,[string]$ArchiveLabel,[string]$OriginalLabel,[string]$GroupName,[string]$Description) {
    $cert=[Security.Cryptography.X509Certificates.X509CertificateLoader]::LoadCertificate($Der)
    try {
        $sha=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Der))
        $id='CERT-'+$sha.Substring(0,20)
        $subject=$cert.Subject
        $expiry=$cert.NotAfter.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ',[Globalization.CultureInfo]::InvariantCulture)
        $encodedArchive=[Uri]::EscapeDataString($ArchiveLabel)
        $encodedMember=[Uri]::EscapeDataString($OriginalLabel)
        $encodedSubject=[Uri]::EscapeDataString($subject)
        $lines=[System.Collections.Generic.List[string]]::new()
        $lines.Add('# Certificate: '+$(if($Description){$Description}else{$subject}))
        $lines.Add('# Source: '+$ArchiveLabel+' :: '+$OriginalLabel)
        $lines.Add('# SHA256 DER: '+$sha)
        $lines.Add('# Imported trust: NO; authorization: NOT ESTABLISHED')
        $lines.Add("@CERT|$id|$GroupName|$encodedArchive|$encodedMember|$encodedSubject|$sha|$expiry")
        for($i=0;$i -lt $Der.Length;$i+=24) {
            $end=[Math]::Min($i+24,$Der.Length)
            $atoms=for($j=$i;$j -lt $end;$j++){'0x{0:X2}' -f $Der[$j]}
            $lines.Add(($atoms -join ','))
        }
        $lines.Add('@END')
        return ($lines -join "`n")
    } finally { $cert.Dispose() }
}

try {
    $inputFile=Get-Item -LiteralPath $CertificatePath -ErrorAction Stop
    $found=@(Get-PublicCertificateDer -FileName $inputFile.FullName)
    if($found.Count -eq 0){throw 'No public certificate was extracted.'}
    $done=[System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $blocks=[System.Collections.Generic.List[string]]::new()
    foreach($der in $found){
        $sha=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($der))
        if(-not $done.Add($sha)){continue}
        $blocks.Add((ConvertTo-CatalogBlock -Der $der -ArchiveLabel $inputFile.Name `
            -OriginalLabel $inputFile.Name -GroupName $Group -Description $Label))
    }
    $result=($blocks -join "`n`n")+"`n"
    if($OutputPath -and -not $ConsoleOnly){
        $out=[IO.Path]::GetFullPath($OutputPath)
        $utf8=[Text.UTF8Encoding]::new($false)
        $file=[IO.FileStream]::new($out,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        try {
            [byte[]]$contents=$utf8.GetBytes($result)
            $file.Write($contents,0,$contents.Length)
            $file.Flush($true)
        } finally {$file.Dispose()}
        Write-Output "Wrote $($blocks.Count) public certificate blocks: $out"
        Write-Output 'Open that text file, copy its @CERT...@END blocks inside main.ps1''s $EmbeddedCertificateHex here-string.'
        Write-Output 'Any edit to main.ps1 changes its SHA256 and invalidates its previously pinned Scheduled Task source.'
    } else {
        Write-Output $result
    }
} catch {
    Write-Error "Certificate-to-hex conversion rejected: $($_.Exception.Message)" -ErrorAction Continue
    exit 1
}
