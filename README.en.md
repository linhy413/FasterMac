<p align="center"><img src="assets/icon.png" width="140" alt="FasterMac icon"></p>

# FasterMac

macOS productivity utilities for screenshots, clipboard history, image browsing
and file organization — with selected, independently reusable components open sourced.

**Created and maintained by [linhy413](https://github.com/linhy413).**
[中文](README.md) · [Official repository](https://github.com/linhy413/FasterMac)
· [Component documentation](docs/components.md)

The project was initiated and designed by linhy413, with Codex-assisted
development. This repository contains a source subset, not the complete
FasterMac desktop application.

## Download and install

**[Download FasterMac 1.1.9 preview DMG](https://github.com/linhy413/FasterMac/releases/download/v1.1.9/FasterMac-1.1.9-arm64.dmg)**
· [Release notes and SHA-256 checksum](https://github.com/linhy413/FasterMac/releases/tag/v1.1.9)

Requires **Apple Silicon and macOS 13 or later**. Open the DMG and drag FasterMac
to Applications. Quit the old version before replacing it; user data lives
separately in your local user directory.

This preview is ad-hoc signed and **has no Apple Developer ID signature or
notarization**. macOS may block the first launch. After checking the official
source and checksum, follow [Apple's instructions](https://support.apple.com/102445)
in System Settings → Privacy & Security. The complete app preview may be used
free of charge under the separate license included in the DMG; its complete
source is not included in this repository.

If the middle button stops working after an update, re-enable FasterMac in
System Settings → Privacy & Security → Accessibility. An ad-hoc signature change
may require renewed authorization; interception recovers automatically afterward.

## Public components

| Component | Purpose |
| --- | --- |
| [SmartZip naming](Sources/FasterMacKit/Actions/QMSmartZipNaming.m) | Suggest an archive name from meaningful filename fields rather than the enclosing folder |
| [Screenshot geometry](Sources/FasterMacKit/Capture/ScreenshotGeometry.m) | Convert display coordinates, preserve native pixel bounds and position accessories |
| [Drag-shake detector](Sources/FasterMacKit/Windows/DropShelfShakeDetector.h) | Detect rapid reversals while filtering slow movement and small jitter |

The modules are used by the desktop app and come with standalone regression
tests, a static-library build and a command-line example. They do not require
the private application host or create windows.

## Try it

Requires macOS and Apple Command Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/linhy413/FasterMac.git
cd FasterMac
bash scripts/test.sh
.build/smartzip-name /tmp/project-v1-001.png /tmp/project-v1-002.jpg
# project
```

The example prints a suggested name without compressing or changing files.
Run `bash scripts/build.sh` to build `.build/libFasterMacKit.a` independently.

## Desktop application preview

The complete app brings screenshot pinning, clipboard history, continuous image
browsing and column-based file management into one launcher. The screenshots
below show the full app; those interfaces and the workflow host remain proprietary.
The app also includes a permanent “Software Update” action in the bottom-right launcher cell,
with an update icon. It links to this official project and credits linhy413.

![FasterMac file manager](assets/screenshots/file-manager.png)
![FasterMac image viewer](assets/screenshots/image-viewer.png)

Desktop installers and version notes are published in
[Releases](https://github.com/linhy413/FasterMac/releases). The current preview
supports Apple Silicon and macOS 13 or later.

## License and attribution

Public code is licensed under [AGPL-3.0-only](LICENSE), with the permitted
Section 7 author-attribution and origin terms in [ATTRIBUTION.md](ATTRIBUTION.md).
Commercial use is allowed when the applicable license conditions are met.
A separately negotiated [commercial license](COMMERCIAL.md) may be available
for integrations requiring different terms.

The icon and screenshots have separate [branding terms](BRAND.md). Unpublished
app code is outside this license; see [LICENSE-SCOPE.md](LICENSE-SCOPE.md).

Feedback and reproductions are welcome in [Issues](https://github.com/linhy413/FasterMac/issues).
Please read [CONTRIBUTING.md](CONTRIBUTING.md) before proposing code.
When sharing the project, credit **FasterMac by linhy413** and link to this repository.

Copyright © 2026 linhy413. See [NOTICE](NOTICE).
