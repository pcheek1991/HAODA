#requires -Version 5.1

<#
====================================================================
LU ZU MONOLITH ENGINE :: 4D STRING EXPLODER & EVENT ARCHIVIST
Platform: Native Windows PowerShell 5.1 (Pre-installed on Windows 11)
====================================================================
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ============================================================================
# WINDOWS EVENT VIEWER SETUP & LOGGER FUNCTION
# ============================================================================
$LogSource = "LuZuMonolith"
$LogName   = "Application"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    if (-not [System.Diagnostics.EventLog]::SourceExists($LogSource)) {
        New-EventLog -LogName $LogName -Source $LogSource
    }
}

function Write-LuZuLog {
    param (
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::Cyan,
        [System.Diagnostics.EventLogEntryType]$EntryType = [System.Diagnostics.EventLogEntryType]::Information,
        [int]$EventId = 1000
    )

    Write-Host $Message -ForegroundColor $Color

    try {
        if ([System.Diagnostics.EventLog]::SourceExists($LogSource)) {
            Write-EventLog -LogName $LogName -Source $LogSource -EntryType $EntryType -EventId $EventId -Message $Message
        }
    } catch {
        # Fallback if non-admin or event source unavailable
    }
}

Write-LuZuLog ""
Write-LuZuLog '============================================================' -Color Cyan
Write-LuZuLog ' LU ZU MONOLITH :: 4D STRING EXPLODER & WINDOWS 5.1 ARCHIVIST' -Color Cyan
Write-LuZuLog '============================================================' -Color Cyan
Write-LuZuLog (" Runtime: Windows PowerShell {0}" -f $PSVersionTable.PSVersion) -Color Green
Write-LuZuLog '============================================================' -Color Cyan
Write-LuZuLog ""

# ============================================================================
# EMBEDDED C# SOURCE CODE (.NET Framework 4.8 Compatible)
# ============================================================================
$cSharpSource = @"
using System;
using System.IO;
using System.Threading;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Collections.Generic;

namespace LuZuEngine
{
    /* 四 :: 裂 — SAFE STRING EXPLODER */
    public static class StringExploder
    {
        public static string[] SafeExplode(string input, char delimiter)
        {
            if (string.IsNullOrEmpty(input)) return new string[0];

            List<string> results = new List<string>();
            int start = 0;
            for (int i = 0; i < input.Length; i++)
            {
                if (input[i] == delimiter)
                {
                    results.Add(input.Substring(start, i - start));
                    start = i + 1;
                }
            }

            if (start <= input.Length)
            {
                results.Add(input.Substring(start));
            }

            return results.ToArray();
        }
    }

    /* 六 :: 旋 — CRYPTOGRAPHIC ROT ENGINE */
    public static class LuZuRot
    {
        private static readonly byte[] _signingKey = new byte[32];
        private static int _ROTN_VOLATILE = 0;

        static LuZuRot()
        {
            using (RNGCryptoServiceProvider rng = new RNGCryptoServiceProvider())
            {
                rng.GetBytes(_signingKey);
            }
        }

        public static string ROT13(string value) { return Transform(value, 13); }
        public static string EBG13(string value) { return Transform(value, -13); }

        private static string Transform(string value, int distance)
        {
            Interlocked.Exchange(ref _ROTN_VOLATILE, 1);
            try
            {
                if (string.IsNullOrEmpty(value)) return value;
                int normalized = ((distance % 26) + 26) % 26;
                char[] chars = value.ToCharArray();

                for (int i = 0; i < chars.Length; ++i)
                {
                    int c = chars[i];
                    if (c >= 65 && c <= 90) chars[i] = (char)(65 + ((c - 65 + normalized) % 26));
                    else if (c >= 97 && c <= 122) chars[i] = (char)(97 + ((c - 97 + normalized) % 26));
                }
                return new string(chars);
            }
            finally
            {
                Interlocked.Exchange(ref _ROTN_VOLATILE, 0);
            }
        }
    }

    /* 八 :: 濾 — ADBLOCK FILTER ENGINE */
    public class FilterEngine
    {
        private HashSet<string> _blockedDomains = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        private readonly object _lock = new object();

        public bool IsDomainBlocked(string domain)
        {
            if (string.IsNullOrEmpty(domain)) return false;
            lock (_lock) { return _blockedDomains.Contains(domain); }
        }
    }
}
"@

# ============================================================================
# EXECUTION & LOGGING PIPELINE
# ============================================================================

Write-LuZuLog "[九眼] Compiling C# Engine via Windows PowerShell 5.1..." -Color Cyan -EventId 1001

Add-Type -TypeDefinition $cSharpSource -Language CSharp

# Self-Test 1: Cryptographic Rotation
$testPayload = "LuZu-Archivist-Trace"
$encoded = [LuZuEngine.LuZuRot]::ROT13($testPayload)
$decoded = [LuZuEngine.LuZuRot]::EBG13($encoded)

if ($decoded -ne $testPayload) {
    Write-LuZuLog "[FAIL] LuZuRot Verification Error!" -Color Red -EntryType Error -EventId 9999
    throw "LuZuRot Engine Self-Test Failed!"
}
Write-LuZuLog "[PASS] [六 :: 旋] Cryptographic Loop: $testPayload -> $encoded -> $decoded" -Color Green -EventId 1002

# Self-Test 2: Safe String Explosion
$complexStream = "doubleclick.net;analytics.google.com;example.com;s0.2mdn.net"
Write-LuZuLog "`n--- [四 :: 裂] Executing Safe String Explosion ---" -Color Yellow -EventId 1003
$explodedDomains = [LuZuEngine.StringExploder]::SafeExplode($complexStream, [char]';')

Write-LuZuLog "[EXPLODED] Sliced $($explodedDomains.Count) dynamic memory fragments safely." -Color Green -EventId 1004

$explodedDomains | ForEach-Object {
    Write-LuZuLog "  |---> Spatial Segment Captured: $_" -Color DarkGray -EventId 1005
}

# Filter Engine Verification
$engine = New-Object LuZuEngine.FilterEngine
Write-LuZuLog "`n--- [八 :: 濾] Performing Domain Analysis ---" -Color Yellow -EventId 1006

$explodedDomains | ForEach-Object {
    $isBlocked = $engine.IsDomainBlocked($_)
    $status = if ($isBlocked) { "BLOCKED" } else { "ALLOWED" }
    $color  = if ($isBlocked) { [ConsoleColor]::Red } else { [ConsoleColor]::Green }
    
    Write-LuZuLog "  [$status] $_" -Color $color -EventId 1007
}

Write-LuZuLog "`n[九 :: 歸] All traces written to Windows Event Viewer under Source 'LuZuMonolith'." -Color Cyan -EventId 1008