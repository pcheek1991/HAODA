# Lu Zu TAMP Obelisk Zipper

**Version 1.6 | Monolithic PowerShell + embedded C# | Certificate archive and `.ir4` update inspector**

> **Failure never becomes policy. Chosen, never assumed.**
>
> **Security status:** Research, inspection, and archival tooling. This project is **not** a DoD-certified trust-anchor manager, does **not** replace DoD InstallRoot, and does **not** install or remove Windows certificate authorities.

Lu Zu TAMP Obelisk Zipper is a self-contained Windows PowerShell tool for inspecting Trust Anchor Management Protocol (TAMP) messages, archiving updates retrieved from designated DoD PKI endpoints, and examining an embedded catalog of public X.509 certificates. Its companion utility converts additional public certificates into reproducible, labeled `0xNN` hexadecimal blocks for inclusion in the monolithic source.

The primary goal is to make complex PKI data inspectable, attributable, repeatable, and auditable without silently expanding system trust.

## At a glance

| Capability | Included behavior |
| --- | --- |
| Single-file execution | `main.ps1` contains the embedded C# engine and public-certificate catalog. |
| Public X.509 catalog | **235 distinct DER certificates** from **8 supplied ZIP archives**. |
| Archive provenance | **676 source appearances**, including duplicates, documented in CSV inventories and source comments. |
| Atomic hexadecimal representation | Byte-for-byte public DER encodings as `0x00` through `0xFF` atoms. |
| Local `.ir4` support | Discover, inspect, or acquire local TAMP messages, including selected ZIP entries. |
| HTTPS retrieval | Download `.ir4` candidates from four fixed DoD-hosted group endpoints. |
| Automatic update checks | Opt-in daily Windows Scheduled Task; download, inspect, archive, and log. |
| Verbose trace | `-vv` enables nine checkpoints for the download/inspection path. |
| Companion converter | Independent `companion.ps1` plus drag-and-drop `.cmd` launcher. |
| Certificate installation | **Not implemented.** No Windows certificate-store writes. |
| Official DoD update authorization | **Not implemented.** Structural inspection is not authority verification. |

## Requirements

- **Windows 11** or a compatible Windows environment with Windows Task Scheduler (the scheduled-task features are Windows-specific).
- **PowerShell 7.6.6 or later** (`pwsh`), with the .NET cryptography assemblies shipped with that runtime.
- A local directory for output and an approved way to execute reviewed PowerShell scripts.
- Network connectivity **only** for `Obelisk`, `AcquireOnline`, or `AutoUpdate`. Other modes use local data, although Windows trust-chain behavior is not asserted to be independent of operating-system configuration.

No additional PowerShell modules, NuGet packages, private keys, or separate C# compilation step are supplied or required by the project. Embedded C# is compiled in memory by `Add-Type`.

## Package contents

| File | Purpose |
| --- | --- |
| `main.ps1` | Monolithic PowerShell program, C# TAMP inspector, 235 public DER certificates. |
| `companion.ps1` | Independent certificate-to-hex conversion tool. |
| `drag-cert-onto-me.cmd` | Windows Explorer drag-and-drop launcher for `companion.ps1`. |
| `Obelisk-v1.6-Certificates.csv` | Unique certificate identities, issuers, dates, hashes, and classification fields. |
| `Obelisk-v1.6-Provenance.csv` | Source archive and ZIP member for all 676 certificate appearances. |
| `Obelisk-v1.6-Sources.csv` | The eight source archive fingerprints and appearance counts. |
| `Obelisk-v1.6-SHA256-MANIFEST.csv` | Original package-file fingerprints. |
| `Obelisk-v1.6-README.txt` | Technical notes accompanying the original v1.6 package. |
| `README.md` | This GitHub-friendly operating guide. |

The catalogs intentionally include expired and test certificates so an inventory does not omit inconvenient entries. **Inclusion does not mean a certificate is safe or appropriate to trust.** In particular, JITC and WCF materials have specialized purposes and must not be indiscriminately imported into Windows trust stores.

## Quick start

Open **PowerShell 7.6.6+**, navigate to the extracted kit, and inspect the scripts before running them.

### 1. Verify source integrity

The SHA-256 fingerprint of the original **v1.6** `main.ps1` distributed with this kit is:

```text
D929BAFF3DCA0F77FFA2CA7698B39EA38D43DCFD4E14962B26478D9F2E13B7DE
```

```powershell
Set-Location "$HOME\Downloads\LuZu-TAMP-Obelisk-v1.6-Embedded-Certs-Kit"

$script = (Resolve-Path '.\main.ps1').Path
$expected = 'D929BAFF3DCA0F77FFA2CA7698B39EA38D43DCFD4E14962B26478D9F2E13B7DE'
$actual = (Get-FileHash -LiteralPath $script -Algorithm SHA256).Hash

if ($actual -cne $expected) {
    throw "main.ps1 integrity mismatch: $actual"
}

'PASS: v1.6 main.ps1 matches the published kit fingerprint.'
```

This comparison detects changes relative to the fingerprint printed here. **The fingerprint is not a digital signature or independent proof of DoD origin.** For other files, consult `Obelisk-v1.6-SHA256-MANIFEST.csv`; if you edit a file or obtain another release, its fingerprint will change.

### 2. Approve a reviewed script without relaxing system policy

PowerShell may initially refuse an unsigned file extracted from a downloaded ZIP. Check the policy first:

```powershell
Get-ExecutionPolicy -List
Get-AuthenticodeSignature -LiteralPath $script | Format-List Status, StatusMessage
Get-Item -LiteralPath $script -Stream Zone.Identifier -ErrorAction SilentlyContinue
```

If the effective policy is **RemoteSigned**, the hash matches, and you have personally reviewed and approved this specific copy, you may remove its downloaded-file marker:

```powershell
Unblock-File -LiteralPath $script
```

`Unblock-File` neither signs the file nor overrides an **AllSigned** or organization-enforced policy. In those environments, obtain an authorized code signature instead. **Do not disable Smart App Control or use an execution-policy bypass to get this tool running.**

### 3. Validate the engine and embedded catalog

```powershell
pwsh -NoProfile -File $script -Mode SelfTest
pwsh -NoProfile -File $script -Mode VerifyCertificates
pwsh -NoProfile -File $script -Mode CertificateInventory -vv
```

`SelfTest` exercises the cryptographic inspector and a synthetic signed TAMP Status Query. `VerifyCertificates` parses the embedded public certificates and checks their recorded DER hashes. These tests **do not** establish that a real DoD TAMP message is authorized for installation.

## One-shot and automatic `.ir4` updates

**Auto-update means obtaining, structurally inspecting, and archiving `.ir4` update candidates. It does not mean applying trust changes.**

### Fetch one group

```powershell
pwsh -NoProfile -File $script -Mode Obelisk -Group DoD -vv
```

Supported groups are `DoD`, `ECA`, `JITC`, and `WCF`. The C# downloader uses a fixed allowlist of DoD-hosted URLs, including:

```text
https://crl.gds.disa.mil/pke/config/DoD.ir4
```

The download routine applies transport checks, refuses redirects, limits downloads to 8 MiB, and structurally inspects the `.ir4` file. Snapshots have SHA-256-based filenames and are clearly labeled **UNVERIFIED**. TLS transport authentication and ASN.1/CMS parsing are **not** equivalent to TAMP management-signature authorization.

### Check all four groups now

```powershell
pwsh -NoProfile -File $script -Mode AutoUpdate -vv
```

Results are saved under:

```text
%LOCALAPPDATA%\LuZu\TAMP-Obelisk-Zipper\
```

A `history.jsonl` file records group-by-group results, including failures and content hashes. A successful download of unchanged bytes is recorded as `Unchanged`; new content is archived without overwriting the previous snapshot. Any group failures produce a nonzero run result so monitoring can detect incomplete refreshes.

### Enable the daily check (opt-in)

Once manual testing succeeds and you have reviewed the source:

```powershell
pwsh -NoProfile -File $script -Mode EnableAutoUpdate -IReviewedSchedule
pwsh -NoProfile -File $script -Mode AutoUpdateStatus
```

This registers the Windows Scheduled Task named `LuZu-TAMP-Obelisk-Zipper-v1.6`. It runs daily at the selected local clock time (initially about five minutes after registration), **only when the registering user is signed in**, with a limited-privilege interactive token. It does not run as `SYSTEM` and does not use `-ExecutionPolicy Bypass`.

The scheduled command includes a SHA-256 **pin of the script source**. If `main.ps1` changes, its scheduled run refuses the modified code until the task is reviewed and registered again. Earlier v1.5 tasks are separate and are **not** removed by v1.6 commands.

Check task status or remove the v1.6 task when no longer needed:

```powershell
pwsh -NoProfile -File $script -Mode AutoUpdateStatus
pwsh -NoProfile -File $script -Mode DisableAutoUpdate -ConfirmRemoveTask
```

Removing the task leaves archived `.ir4` snapshots untouched.

## Work with `.ir4` messages offline

These commands do **not** contact download endpoints:

```powershell
# Find a locally available DoD.ir4 file.
pwsh -NoProfile -File $script -Mode Discover -Group DoD

# Inspect an existing local message (structure, not authorized origin).
pwsh -NoProfile -File $script -Mode Inspect -MessagePath '.\DoD.ir4'

# Preserve and inspect an existing local copy.
pwsh -NoProfile -File $script -Mode Acquire -Group DoD -SourcePath '.\DoD.ir4'

# Generate an independently signed, TEST-ONLY Status Query.
pwsh -NoProfile -File $script -Mode GenerateTest -OutputDirectory "$HOME\Downloads"
```

The sample DoD `.ir4` previously supplied for development contained **four embedded CMS SignedData messages**. The inspector supports this multi-message batch structure. Reported certificate ADD/REMOVE/CHANGE operations are **proposals being inspected, not operations being executed**.

For the separate `Verify` mode, supply a DER-encoded signer certificate **and** its SHA-256 fingerprint obtained through an independently trusted channel:

```powershell
pwsh -NoProfile -File $script -Mode Verify `
    -MessagePath '.\update.ir4' `
    -SignerCertificatePath '.\authenticated-signer.der' `
    -SignerSha256 'REPLACE_WITH_INDEPENDENTLY_VERIFIED_64_HEX_CHARACTERS'
```

Do not copy a certificate fingerprint solely from the untrusted update being verified. A signature check alone does not implement the complete RFC 5934 authorization model.

## Embedded certificate archive

The v1.6 source includes **235 distinct public DER certificate byte sequences** as labeled `0xNN` atoms. Repeated occurrences are recorded, not duplicated into the payload. The four source families are DoD, ECA, JITC, and WCF, plus the separately supplied external PKI trust-chain archives.

Inventory and hash verification:

```powershell
pwsh -NoProfile -File $script -Mode CertificateInventory
pwsh -NoProfile -File $script -Mode VerifyCertificates
```

Export one certificate (consult `Obelisk-v1.6-Certificates.csv` for its ID):

```powershell
pwsh -NoProfile -File $script -Mode ExportCertificate `
    -CertificateId 'CERT-REPLACE_WITH_ID_FROM_INVENTORY' `
    -OutputDirectory "$HOME\Downloads"
```

Or export all 235 DER certificates to an **existing empty directory**:

```powershell
pwsh -NoProfile -File $script -Mode ExportAllCertificates `
    -OutputDirectory 'C:\TAMP-Certificate-Exports'
```

The export routines use a create-new strategy: existing filenames are **not** overwritten. Exports are named `UNTRUSTED-<SHA256>.cer`. Exporting does not import certificates into a trusted store.

## Independent companion: certificate to `0xNN` blocks

`companion.ps1` is a separate utility. It does **not** call, import, or depend upon `main.ps1`, does not alter certificate stores, and rejects private-key containers such as `.pfx` and `.p12`.

Supported inputs: `.cer`, `.crt`, `.der`, `.pem`, `.p7b`, and `.p7c`. A CMS/PKCS#7 input may yield multiple unique public certificates.

```powershell
pwsh -NoProfile -File '.\companion.ps1' `
    -CertificatePath 'C:\Certificates\example.cer' `
    -Label 'Example CA' `
    -Group UserSupplied `
    -OutputPath 'C:\Certificates\example-hex.txt'
```

The output looks like this (illustrative excerpt, **not** a usable certificate):

```text
# Certificate: Example CA
# Source: example.cer :: example.cer
# SHA256 DER: <full SHA-256 of the actual DER bytes>
# Imported trust: NO; authorization: NOT ESTABLISHED
@CERT|CERT-...|UserSupplied|example.cer|example.cer|...|...|...
0x30,0x82,0x03,0x21,0x30,0x82,0x02,0x09
...
@END
```

To use drag-and-drop, keep `drag-cert-onto-me.cmd` in the same directory as `companion.ps1`, then drop a certificate file **onto the `.cmd` launcher**, not the `.ps1`. The launcher produces a `<filename>-hex.txt` file beside the input and refuses to overwrite an existing output file.

### Add generated blocks to the monolith

1. Review the certificate's provenance, intended use, expiry, and independently established identity.
2. Open the generated `-hex.txt` file.
3. Copy the **entire** `@CERT` through `@END` block into the single-quoted `$EmbeddedCertificateHex` here-string inside `main.ps1`, **before** its closing `'@` line.
4. Save the modified script under a new reviewed filename. Its SHA-256 will be different.
5. Re-run `-Mode SelfTest` and `-Mode VerifyCertificates`; check the inventory for duplicate DER hashes.
6. If a scheduled updater was registered for the earlier source, remove that task and register the reviewed new script so its hash pin reflects the change.

Never embed private keys, passwords, or personal certificates with sensitive key material. The catalog is a **public-certificate evidence archive**, not a request to trust its contents.

## Operating modes

| Mode | Purpose | Network |
| --- | --- | --- |
| `SelfTest` | Cryptography, parser, synthetic message, catalog validation. | No |
| `CertificateInventory` / `VerifyCertificates` | Read and validate embedded public certificates. | No |
| `ExportCertificate` / `ExportAllCertificates` | Export public DER certificates as untrusted `.cer` files. | No |
| `Discover` | Find local group-specific `.ir4` files. | No |
| `Acquire` | Read an existing local `.ir4` or ZIP and make an inspected copy. | No |
| `Inspect` | Parse local `.ir4` message structures. | No |
| `Verify` | Verify supported CMS signatures against an explicitly pinned signer certificate. | No |
| `GenerateTest` | Create a signed, synthetic TAMP Status Query. | No |
| `Obelisk` / `AcquireOnline` | Download and inspect one group. | **Yes** |
| `AutoUpdate` | Download and archive all four groups, record JSONL history. | **Yes** |
| `EnableAutoUpdate` / `DisableAutoUpdate` | Register/remove a user-scoped daily Windows task. | No, for task configuration itself |
| `AutoUpdateStatus` | Show the registered task state. | No |

## Security model and limitations

1. **No operating-system trust-store writes.** Certificate export, inspection, and acquisition remain separate from Windows certificate installation.
2. **Embedded is not trusted.** Certificate catalogs and manifest signatures may establish byte integrity relative to their inputs, not an independently established management hierarchy.
3. **Transport is not management authorization.** HTTPS identity checks and ASN.1/CMS structure checks do not prove that an `.ir4` message may change local trust anchors.
4. **Incomplete TAMP enforcement.** DoD management authority, full CA-path validation, revocation, allowed target selection, subordination, persistent anti-replay state, and transactional add/remove/change application remain unimplemented.
5. **Test and specialized CAs stay untrusted.** JITC, WCF, expired, and external PKI certificates are archived for evidence, not blanket installation.
6. **No code-signing claim.** The published `main.ps1` is not Authenticode signed. Integrity hashes are not signatures.
7. **No DoD endorsement or compliance claim.** This project is not certified by DoD, DISA, or another public authority, and successful operation does not demonstrate STIG or SCAP compliance.

For operational PKI administration, use the official DoD-approved procedures and validated InstallRoot distribution while developing and independently assessing additional TAMP authorization capabilities.

## Troubleshooting

**“File ... is not digitally signed.”** Inspect `Get-ExecutionPolicy -List` and the file's `Zone.Identifier`. If policy is `RemoteSigned`, and only after source review and hash verification, `Unblock-File -LiteralPath $script` may be appropriate. If `AllSigned` or organizational policy applies, have the script properly signed.

**“Scheduled source changed.”** The task's SHA-256 pin no longer matches `main.ps1`. Inspect the source changes, run tests, and re-register the task. Do not remove the pin.

**`.ir4` acquisition rejected.** Check TLS connectivity, endpoint availability, disk permissions, and the verbose nine-eye trace. Preserve the rejection output; do not install the rejected message.

**Export refuses to overwrite.** Choose a new or empty output directory. Existing exports are intentionally preserved.

**Companion refuses a `.pfx`/`.p12`.** This is intentional. Export only the *public certificate* in DER/PEM form through an approved procedure.

**Auto-update task did not run while logged out.** The registered task uses an interactive user token and is intentionally configured to run only when the user is signed in.

## Development and attribution

The single-file embedded-C# architecture and recurring-refresh concept were inspired by the user's [Lu Zu Monolith example](https://github.com/pcheek1991/chausterbittdancing/blob/main/main.ps1). The nine-eye diagnostic concept is a visualization-inspired convention, not a cryptographic trust assessment.

Standards reference: [RFC 5934, Trust Anchor Management Protocol (TAMP)](https://www.rfc-editor.org/rfc/rfc5934).

**Repository status:** No software license is asserted by this README. Add an explicit `LICENSE` file only when the project owner chooses the terms.

---

**Safety principle:** *Failure never becomes policy. Chosen, never assumed.*
