# Coreo ToricLens v1.0

This is an opt-in educational optics component, separate from the TAMP kits. It contains a small PowerShell entrypoint and an in-memory compiled C# implementation of `Coreo.Optics.ToricLensPower`.

## Runtime and usage

The component requires **PowerShell 7.6.7 exactly**. The entrypoint has a `#requires` directive and checks the exact runtime before compiling or running the C# source.

From this directory:

```powershell
pwsh -NoLogo -NoProfile -File .\Invoke-Coreo.ps1 -Mode Profile
pwsh -NoLogo -NoProfile -File .\Invoke-Coreo.ps1 -Mode SelfTest
pwsh -NoLogo -NoProfile -File .\tests\Test-Coreo.ps1
```

`Profile` is the default mode. It defaults to Sphere `-2.50`, Cylinder `-1.25`, Axis `0` degrees, and the sample meridians `0, 30, 45, 60, 90, 135, 180`. The sphere, cylinder, axis, and meridians can be supplied as parameters. Power is displayed in diopters with two decimal places using midpoint-to-even rounding; calculations and tests retain the raw `double` result.

## Calculation

The component implements:

```text
P(theta) = Sphere + Cylinder * sin^2(theta - axis)
```

Angles are supplied in degrees and converted to radians for the sine calculation. The axis is normalized into `[0, 180)`. Omitting the C# axis argument uses `0` degrees.

For Sphere `-2.50`, Cylinder `-1.25`, and Axis `0`, the profile display is:

| Meridian | Effective Power |
| --- | --- |
| 0° | −2.50 D |
| 30° | −2.81 D |
| 45° | −3.12 D |
| 60° | −3.44 D |
| 90° | −3.75 D |
| 135° | −3.12 D |
| 180° | −2.50 D |

The raw expected powers are `-2.50`, `-2.8125`, `-3.125`, `-3.4375`, `-3.75`, `-3.125`, and `-2.50` in that order.

## Read-only certificate-store summary

`StoreAudit` is a separate, explicit mode:

```powershell
pwsh -NoLogo -NoProfile -File .\Invoke-Coreo.ps1 -Mode StoreAudit
```

It opens the standard `CurrentUser` and `LocalMachine` stores with `X509Store.Open(OpenFlags.ReadOnly)` and reports only store location, store name, and certificate count. It does not export certificates or change trust. The profile, self-test, and test script do not inspect certificate stores. The audit mode is not part of TAMP processing and is not run by these tests.

## CI

The workflow downloads the official PowerShell 7.6.7 Windows x64 ZIP, verifies its pinned SHA-256 against the release checksum and GitHub asset digest, then runs the focused tests with that runtime. It does not run `StoreAudit`.

## Scope and limitations

This component is educational software, not medical advice or a clinically validated lens prescription tool. It makes no DoD certification, endorsement, or compliance claim. It does not contact TAMP endpoints, perform TAMP processing, write files, or modify certificate stores.
