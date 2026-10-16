# PERIODBLOCKER

### A small field guide to domain-list classification

Four platform-native scripts trace one fixed sample list through a simple
classifier and into local logging.

> **They report labels; they do not block network traffic.**

**Learning demo** · **Static inputs** · **No network enforcement**

---

## 🧭 The scripts

| File | Runtime | Output |
| --- | --- | --- |
| `main_macos.sh` | macOS, Zsh, and `python3` | Console and `logger` (`LuZuMonolith`) |
| `main_ubuntu.sh` | Ubuntu, Bash, `tr`, and `logger` | Console and `logger` (`LuZuMonolith`) |
| `main_win.ps1` | Windows PowerShell 5.1 | Console and best-effort Application Event Log |
| `coreo.sh1` | Windows PowerShell Core 7.6.6 or newer | Console and best-effort Application Event Log |
| `coreo\optics\ToricLens.ps1` | PowerShell Core 7.6.7 (exact) | Optional TORIC lens profile, self-test, and read-only certificate-store summary |

The shell scripts use a hard-coded four-domain sample. The PowerShell scripts
split the same sample string with an embedded C# helper. Nothing downloads or
refreshes a list.

## Optional TORIC lens COREO component

`coreo\optics\ToricLens.ps1` is a separate educational optics calculation; it
does not participate in domain classification or change any existing script.
It requires exactly PowerShell 7.6.7 and checks that runtime before loading the
C# implementation in `coreo\optics\ToricLensPower.cs`.

The model is `P(theta) = Sphere + Cylinder * sin^2(theta - axis)`, with angles
in degrees and axis normalized to `[0, 180)`. The default axis is 0 degrees.
Run the sample profile or its formula/axis self-test with:

```powershell
pwsh.exe -NoProfile -File .\coreo\optics\ToricLens.ps1 -Mode Profile
pwsh.exe -NoProfile -File .\coreo\optics\ToricLens.ps1 -Mode SelfTest
```

The sample profile uses Sphere=-2.50 D and Cylinder=-1.25 D:

| Meridian | Effective Power |
| --- | ---: |
| 0° | −2.50 D |
| 30° | −2.81 D |
| 45° | −3.12 D |
| 60° | −3.44 D |
| 90° | −3.75 D |
| 135° | −3.12 D |
| 180° | −2.50 D |

Profile display rounds to two decimal places using midpoint-to-even rounding;
the self-test checks the unrounded numeric values with a tolerance.

`-Mode StoreAudit` is a separate, explicit summary of the selected certificate
store (default `CurrentUser\My`). It opens the store with
`X509Store.Open(OpenFlags.ReadOnly)` and reports counts only; it performs no
certificate imports, additions, removals, or trust changes. Neither the
self-test nor CI invokes this mode, and no store inspection was run on the
developer workstation.

This component is an educational optics calculation, not an ad blocker,
medical advice, DoD-certified code, or a compliance claim.

## ▶️ Run a sample

Run commands from the repository root. Review each script before running it.

**macOS**

```sh
zsh ./main_macos.sh
```

Requires `zsh`, `python3`, and the system `logger` command.

**Ubuntu Linux**

```sh
bash ./main_ubuntu.sh
```

Requires Bash, `tr`, and the system `logger` command.

**Windows PowerShell 5.1**

```powershell
powershell.exe -NoProfile -File .\main_win.ps1
```

**Windows PowerShell Core 7.6.6+**

`coreo.sh1` contains PowerShell code but has a nonstandard file extension.
Make a `.ps1` copy before using `-File`:

```powershell
Copy-Item .\coreo.sh1 .\coreo.ps1
pwsh.exe -NoProfile -File .\coreo.ps1
```

## 🔎 What the labels mean

The macOS and Ubuntu scripts label `doubleclick.net` and `s0.2mdn.net` as
`BLOCKED`; the other two sample names are labelled `ALLOWED`. The PowerShell
scripts' filter set is never populated, so they label every sample name
`ALLOWED`.

These are text classifications only. The scripts do **not** change DNS,
firewall rules, browser settings, or the hosts file, and do not intercept or
block requests. The sample list is fixed in the source.

## ⚠️ Scope and side effects

- ROT13 is a reversible text rotation, not encryption. Despite comments in
  the source, no script computes an HMAC or digital signature; the random
  signing-key field in the PowerShell code is never used to sign anything.
- The source's "zero-allocation" wording is not accurate: these examples
  create strings, arrays, and lists.
- macOS and Ubuntu send messages to the system `logger` command. Where those
  messages appear depends on the operating system's logging configuration.
- The Windows scripts print to the console and attempt Event Log writes. If
  run elevated and the source is missing, they may create the persistent
  `LuZuMonolith` source in the `Application` log. Event Log write failures are
  ignored; an error while creating the source can stop startup.

Treat this repository as an educational classification-and-logging sample,
not as an ad blocker or security control.

## Automated validation

GitHub Actions validates the scripts on ephemeral, GitHub-hosted native
runners. The Windows Server 2022 job uses Windows PowerShell 5.1 to extract and
compile the embedded C# and check its ROT13 and sample-splitting logic without
running `main_win.ps1` or touching the Event Log. This covers Windows Server,
not Windows 11 itself.

The Ubuntu job syntax-checks `main_ubuntu.sh` and runs its fixed sample,
checking the classifications with a temporary no-op `logger`. The macOS job
does the same for `main_macos.sh` using native Zsh. macOS is tested on a native
runner, not in a container. Neither shell script makes network requests; the
logger shim prevents system-log writes, and the jobs do not touch hosts, DNS,
or firewall settings. An additional Windows job downloads the
checksum-verified PowerShell 7.6.7 portable release and runs only the focused
ToricLens tests; it does not invoke the certificate-store mode. These jobs run
on ephemeral hosted machines, not a developer's workstation.
