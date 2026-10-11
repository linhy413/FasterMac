# Changelog

## Desktop preview 1.1.9 — 2026-10-11

- Rename the permanent project action to “Software Update”, with an update icon and default bottom-right placement. Existing actions are preserved during migration.
- Recover middle-button interception when Accessibility permission is granted after startup; remove the non-consuming fallback that lets Chrome clear the selection.
- Preserve selected text before showing the launcher, handle slower copy responses, and restore the original clipboard.
- Add a required selection-preservation regression to every build and DMG package.

The desktop preview remains Apple Silicon / macOS 13+, ad-hoc signed and not notarized. Updating may require renewed Accessibility authorization. The complete desktop app remains proprietary; public component licensing is unchanged.

## 0.1.0 — 2026-10-11

First public component release by [linhy413](https://github.com/linhy413).

- SmartZip archive-name selection and Finder selection script generator.
- Screenshot coordinate conversion, pixel crop bounds and accessory placement.
- Drag-shake gesture detector with timing and jitter filtering.
- Standalone static library, command-line example and component regression tests.
- AGPL-3.0-only licensing with author attribution and origin terms.

This is the version of the public components, independent of the full FasterMac app version.
