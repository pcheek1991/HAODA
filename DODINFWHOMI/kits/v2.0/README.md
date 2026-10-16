# Lu Zu TAMP Obelisk Zipper v2.0

**Windows PowerShell 5.1 edition | Embedded C# | DoD PKI candidate-message archiving | Read-only certificate-store audit**

> **Failure never becomes policy. Chosen, never assumed.**

This distribution targets **Windows 11's built-in Windows PowerShell 5.1** (`powershell.exe`, Desktop edition) and **.NET Framework 4.8+**. It does **not** require `pwsh.exe`, PowerShell 7, external .NET packages, or third-party installers. The `main.ps1` file is monolithic: the C# engine and all public certificate DER bytes are embedded in the script. All functionality runs under the caller's ordinary Windows account. **No elevation is requested.**

## What is included

| File | Purpose |
|---|---|
| `main.ps1` | Main monolithic Windows PowerShell 5.1 script with embedded C# and **235 distinct DER certificates** represented as individually labeled `0xNN` bytes |
| `companion.ps1` | **Independent** public certificate-to-hex converter; supports `.cer`, `.crt`, `.der`, `.pem`, `.p7b`, `.p7c` |
| `drag-cert-onto-me.cmd` | Windows drag-and-drop launcher for the companion, using built-in `powershell.exe` |
| `README.md` | Installation, commands, security design, audit interpretation, troubleshooting |
| `Certificates.csv` | Identity, validity and SHA-256 inventory of the embedded certificates |
| `Provenance.csv` | The original archive/member occurrence list, including duplicates |
| `Sources.csv` | Original ZIP inventory |
| `SHA256-MANIFEST.csv` | SHA-256 fingerprints for the distributed source and documentation files |

Source extraction: **8 supplied ZIP archives, 676 recorded source occurrences, 235 distinct public certificates**. The distinct DER records and their SHA-256 digests have been independently cross-checked against the prior v1.6 catalog. DoD, ECA, JITC, WCF and external-source certificates are all retained as **public reference data**. No private keys are embedded.

## Security model and boundaries

**Read-only certificate inspection:** `StoreAudit` enumerates the standard logical X.509 stores available through .NET Framework's `X509Store` API in both `CurrentUser` (`certmgr.msc`) and `LocalMachine` (`certlm.msc`), including `Root`, `CertificateAuthority`, `My`, `AuthRoot`, `Disallowed`, `TrustedPeople`, `TrustedPublisher` and `AddressBook`, where accessible. It matches **exact DER SHA-256 fingerprints** and reports the corresponding Windows **SHA-1 thumbprint** only for MMC lookup convenience. It reports validity, CA basic constraints, self-issued status and every matching store location. A missing or unreadable store is *not* silently treated as proof of absence.

**Presence is not correctness:** A certificate found in a store is not necessarily correctly installed or approved for that role. Conversely, absence of a JITC test, WCF interception, expired or external-chain certificate can be intentional and correct. Do **not** attempt to install all 235 certificates. The program does not have a independently authenticated DoD STIG/InstallRoot authorization baseline to determine which roots or intermediates should be trusted on a given workstation. The audit does not read every possible Group Policy/Enterprise physical-store partition separately and cannot claim exhaustive MMC coverage.

**DoD `.ir4` handling:** Online modes contact only the built-in DoD PKI URLs, reject redirects, enforce operating-system TLS certificate verification (including revocation checking), enforce 8-MiB input limits, structurally parse single or batch CMS/TAMP messages, and save content-addressed files labeled **UNVERIFIED**. The scheduled auto-update uses the **current user's non-elevated** Windows Task Scheduler identity and the hash of the approved script. Offline modes make no HTTP requests. Neither online nor offline modes authenticate the real DoD TAMP management-authority chain, check its authorization/subordination, validate application-specific replay state or apply trust-anchor changes. **No X509Store.Add/Remove operations are present.** Updating downloaded `.ir4` snapshots is **not** automatic installation of certificates.

**Test fixture:** Windows PowerShell 5.1/.NET Framework lacks the convenient modern certificate-generation API used by the previous test harness. This edition embeds a small pre-signed, public-only CMS StatusQuery test vector with a self-signed test certificate and no private key. `GenerateTest` writes the public fixture, it does not sign a new DoD update.

## Requirements

- Windows 11 and Windows PowerShell **5.1** (`$PSVersionTable.PSEdition` is `Desktop`).
- .NET Framework **4.8 or newer** (normally present on supported Windows 11 systems).
- No external DLLs, remotes, or PowerShell 7 runtime.
- Internet access **only** for `Obelisk`, `AcquireOnline`, `AutoUpdate` and a registered scheduled update.
- Run from a local, non-reparse-point path. The script rejects UNC/network files for its local input workflow.

## Start here

Open **Windows PowerShell** (not the PowerShell 7 terminal). From your unzipped directory:

```powershell
$script = (Resolve-Path '.\main.ps1').Path
$PSVersionTable | Select-Object PSVersion, PSEdition
Get-FileHash -LiteralPath $script -Algorithm SHA256
Get-ExecutionPolicy -List
```

Compare the SHA-256 with `SHA256-MANIFEST.csv`. Review the source before execution. Under an effective `RemoteSigned` policy, the downloaded script may have a `Zone.Identifier` Mark of the Web. **Only after verifying and approving the script**, a local approved copy may be handled with `Unblock-File -LiteralPath $script`. `Unblock-File` does **not** override `AllSigned` or an organization's enforcement policy. If `AllSigned` is active, properly sign the script using an organization-approved trusted code-signing certificate instead. Do not use execution-policy bypass or disable Smart App Control.

Run diagnostics:

```powershell
powershell.exe -NoLogo -NoProfile -File $script -Mode SelfTest
powershell.exe -NoLogo -NoProfile -File $script -Mode VerifyCertificates
```

`SelfTest` checks ASN.1 error rejection, SHA-256 test vectors, a pre-signed CMS fixture, pinned signer selection, tamper detection, and batch framing. It has not been run under Windows PowerShell in the authoring environment; run this first on your workstation and share any errors for correction.

## NEW: inspect Windows certificate stores

List summary counts without generating a report:

```powershell
powershell.exe -NoLogo -NoProfile -File $script -Mode StoreAuditSummary
```

Save **all 235** catalog comparison results to a new CSV (will not overwrite an existing CSV):

```powershell
powershell.exe -NoLogo -NoProfile -File $script `
    -Mode StoreAudit `
    -AuditCsvPath "$env:USERPROFILE\Downloads\certificate-store-audit.csv"
```

Show each certificate's matching store location and a placement-review note:

```powershell
powershell.exe -NoLogo -NoProfile -File $script -Mode StoreAudit -vv
```

The CSV has these columns:

- `Id`, `Group`, `Subject`: embedded certificate identity and source category.
- `SHA256Der`: exact DER fingerprint used for matching; `SHA1Thumbprint`: MMC-style identification.
- `IsCA`, `SelfIssued`, `Expired`, `NotAfterUtc`: descriptive properties. `Expired` includes not-yet-valid records as a validity warning.
- `Presence`: `FOUND` or `NOT_FOUND_IN_SCANNED_STORES`.
- `StoreLocations`: semicolon-delimited CurrentUser / LocalMachine store locations.
- `PlacementReview`: prompts comparison against an independently approved baseline; it does not confer trust.

### MMC cross-check

Run `certmgr.msc` for **Current User** stores and `certlm.msc` for **Local Computer** stores. Look in **Trusted Root Certification Authorities** (`Root`), **Intermediate Certification Authorities** (`CertificateAuthority`), **Untrusted Certificates** (`Disallowed`), and the other named stores. The script scans those *logical* stores, not all MMC physical/policy overlays. If some scans fail, the audit emits warnings with the particular location. Run under the account whose Current User stores you mean to assess. Administrative elevation is **not needed**, although policy can limit store visibility.

**No list of 235 'required installations' is inferred.** To confirm correctness against an approved organization-specific baseline, compare the exported CSV with that baseline and the official DoD InstallRoot management state. Be particularly careful with JITC test and WCF certificates, and do not introduce them as general-purpose trusted roots.

## Automatic DoD update-message snapshots

Manually fetch and inspect the DoD `.ir4` candidate:

```powershell
powershell.exe -NoLogo -NoProfile -File $script -Mode Obelisk -Group DoD -vv
```

Check four configured groups (DoD, ECA, JITC, WCF), write snapshots to `%LOCALAPPDATA%\LuZu\TAMP-Obelisk-Zipper\` and append JSONL logs:

```powershell
powershell.exe -NoLogo -NoProfile -File $script -Mode AutoUpdate -vv
```

Opt into **daily scheduled checks**, after the one-shot update and the self-test work:

```powershell
powershell.exe -NoLogo -NoProfile -File $script -Mode EnableAutoUpdate -IReviewedSchedule
powershell.exe -NoLogo -NoProfile -File $script -Mode AutoUpdateStatus
```

The task runs **only when its user is logged on**, without SYSTEM privileges, and uses the built-in `powershell.exe`. Its script SHA-256 is pinned. If you edit the script or append a new certificate record, re-register the task after review, because its previous hash should no longer match.

Unregister the task explicitly:

```powershell
powershell.exe -NoLogo -NoProfile -File $script -Mode DisableAutoUpdate -ConfirmRemoveTask
```

No scheduled task is registered by merely running SelfTest, StoreAudit, or AutoUpdate once. Automatic snapshots do not mean automatic certificate installation.

## Local TAMP and embedded certificate commands

```powershell
powershell.exe -NoLogo -NoProfile -File $script -Mode Inspect -MessagePath '.\DoD.ir4'
powershell.exe -NoLogo -NoProfile -File $script -Mode Discover -Group DoD
powershell.exe -NoLogo -NoProfile -File $script -Mode Acquire -Group DoD -SourcePath '.\DoD.ir4'
powershell.exe -NoLogo -NoProfile -File $script -Mode CertificateInventory -vv
powershell.exe -NoLogo -NoProfile -File $script -Mode GenerateTest
```

Use `-Mode Verify` **only with a separately authenticated signer certificate and independently authenticated 64-character SHA-256 certificate pin**:

```powershell
powershell.exe -NoLogo -NoProfile -File $script -Mode Verify `
  -MessagePath '.\TEST-ONLY-NOT-DOD-StatusQuery.ir4' `
  -SignerCertificatePath '.\TEST-ONLY-NOT-DOD-Signer.der' `
  -SignerSha256 '<SHA256 certificate pin from independently trusted source>'
```

The synthetic test certificate is not a DoD signer. `Verify` validates the supported CMS signature against the supplied pin; it is not a complete DoD TAMP update authorization test. The example placeholder must be replaced by a real fingerprint or the command will be rejected.

Export one public embedded certificate by `-CertificateId` (from the inventory), or the whole archive:

```powershell
powershell.exe -NoLogo -NoProfile -File $script -Mode ExportCertificate -CertificateId 'CERT-<20 hexadecimal characters>'
powershell.exe -NoLogo -NoProfile -File $script -Mode ExportAllCertificates
```

Exporting a `.cer` file is **not** importing it into a trust store. All exports are labeled `UNTRUSTED-*` and refuse overwrites.

## Standalone companion and drag-and-drop

Double-click `drag-cert-onto-me.cmd` with a public certificate file dropped onto it, or execute directly:

```powershell
powershell.exe -NoLogo -NoProfile -File '.\companion.ps1' `
  -CertificatePath 'C:\Certificates\sample.cer' `
  -Label 'Reviewed Public Certificate' `
  -Group UserSupplied `
  -OutputPath 'C:\Certificates\sample-hex.txt'
```

The companion writes clearly labeled `@CERT|...` records, 24 `0xNN` bytes per line and an `@END` marker. Paste only *public certificate records* into the `$EmbeddedCertificateHex` here-string within `main.ps1`, before its terminating `'@` line, after reviewing them. This changes the file's SHA-256, so any previously pinned daily update task must be re-registered. `.pfx` / `.p12` and private keys are not supported.

## Operational limits and testing status

- Static checks confirm the monolithic catalog is unchanged and every reconstructed DER fingerprint matches its catalog SHA-256; the kit/manifest and ZIP consistency are verified.
- The pre-signed public-only CMS fixture was cryptographically verified with OpenSSL in the authoring environment.
- **Native execution and embedded C# compilation under Windows PowerShell 5.1 are not available in the authoring environment.** The first local `-Mode SelfTest` run is therefore required before treating this as a working Windows 11 edition.
- No SCT/SCAP/STIG compliance claim is made; no management-authority verification, replay enforcement, signed baseline decision, revocation chain evaluation or certificate-store modification is implemented.
- Windows may apply different Enterprise / Group Policy physical stores or user-specific trust contexts. The store audit reports only the standard logical stores that can be opened.

**Failure never becomes policy. Chosen, never assumed.**
