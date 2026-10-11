// Copyright (c) 2026 linhy413.
// SPDX-License-Identifier: AGPL-3.0-only
// Section 7 attribution and origin terms: see ATTRIBUTION.md.
// Official project: https://github.com/linhy413/FasterMac

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Returns a stable, human-readable archive name without the .zip extension.
/// Single items keep their own name. Multiple items prefer fields shared by
/// the largest number of selected names, then fall back to a common prefix or
/// one of the selected item names. The containing folder is never used.
FOUNDATION_EXPORT NSString *QMSmartZipArchiveBaseName(NSArray<NSURL *> *urls);

/// Finder script used after compression. It clears the old selection, retries
/// selecting the archive, verifies the internal selection, and leaves it empty
/// rather than preserving stale source items if verification fails.
FOUNDATION_EXPORT NSString *QMSmartZipFinderSelectionScript(void);

NS_ASSUME_NONNULL_END
