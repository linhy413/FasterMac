# Public components

These are source snapshots of modules used in the FasterMac desktop application.
They do not start the host app, register global event monitors or create windows.
Build and run tests with Apple Command Line Tools on macOS:

```sh
bash scripts/test.sh
```

## SmartZip naming

`Actions/QMSmartZipNaming.h` exposes:

- `QMSmartZipArchiveBaseName(NSArray<NSURL *> *)`: suggests a readable name
  without `.zip`, using shared meaningful filename fields, a common prefix
  or a selected item's name. It excludes common version/sequence noise and
  never uses the enclosing folder as a fallback.
- `QMSmartZipFinderSelectionScript()`: returns AppleScript source that clears
  stale Finder selection and retries selecting supplied result paths. This
  function only returns text. Executing that script is a separate integration
  step that can activate Finder and require Automation permission.

```objc
#import "Actions/QMSmartZipNaming.h"
NSString *name = QMSmartZipArchiveBaseName(@[
    [NSURL fileURLWithPath:@"/tmp/品牌图_v1_001.jpg"],
    [NSURL fileURLWithPath:@"/tmp/品牌图_v1_002.png"]
]); // 品牌图
```

The naming function may query local URL directory metadata. It does not read
file contents, compress files, move files or execute scripts.

## Screenshot geometry

`Capture/ScreenshotGeometry.h` provides six functions for drag rectangles,
clamping, AppKit-to-capture coordinate conversion, native pixel dimensions,
pixel-aligned crop bounds and accessory placement. Use the selected display's
actual frame and the snapshot's actual pixel dimensions, especially on mixed-DPI
and negative-origin displays. These functions perform calculations only;
they do not take screenshots or request screen-recording access.

```objc
#import "Capture/ScreenshotGeometry.h"
NSRect pixels = QMScreenshotPixelCropRect(
    NSMakeRect(10.25, 20.5, 100.5, 50.25),
    NSMakeSize(500, 300), NSMakeSize(1000, 600)
); // {20, 41, 202, 101}
```

## Drag-shake detection

`Windows/DropShelfShakeDetector.h` is a header-only detector. Initialize one
`QMDropShelfShakeDetector` per drag session and feed cursor points with
monotonically increasing time in seconds. It tracks rapid direction reversals,
filters short jitter and resets after a successful gesture. The caller decides
when a drag begins/ends and what a detected gesture should do.

```objc
#import "Windows/DropShelfShakeDetector.h"
QMDropShelfShakeDetector detector;
QMDropShelfShakeDetectorInit(&detector);
BOOL detected = QMDropShelfShakeDetectorFeed(&detector, CGPointMake(20, 0), 0.1);
```

The detector itself does not read the mouse, monitor events, access the
pasteboard or create a shelf. The `Windows/` folder preserves its upstream
module path; it does not introduce a window-controller dependency.

## Integration

`bash scripts/build.sh` creates `.build/libFasterMacKit.a`. Add
`Sources/FasterMacKit` to your header search path, include `FasterMacKit.h`
or an individual module header, and link Foundation and AppKit. The library
targets the current build machine's architecture. There is no dependency
manager or bundled runtime dependency.

When copying components into another project, include LICENSE, NOTICE and
ATTRIBUTION.md and comply with [LICENSE-SCOPE.md](../LICENSE-SCOPE.md).
The public library does not include clipboard history, image viewer,
file-manager UI, the action host, or the workflow runtime.
