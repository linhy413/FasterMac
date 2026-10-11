// Copyright (c) 2026 linhy413.
// SPDX-License-Identifier: AGPL-3.0-only
// Section 7 attribution and origin terms: see ATTRIBUTION.md.
// Official project: https://github.com/linhy413/FasterMac

#import <Foundation/Foundation.h>
#import "Actions/QMSmartZipNaming.h"

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            fprintf(stderr, "Usage: smartzip-name <path> [path ...]\n"
                    "FasterMac by linhy413 — https://github.com/linhy413/FasterMac\n"
                    "Prints a suggested archive name; does not compress or change files.\n");
            return 2;
        }
        NSMutableArray<NSURL *> *urls = NSMutableArray.array;
        for (int index = 1; index < argc; index++) {
            NSString *path = [NSString stringWithUTF8String:argv[index]];
            if (!path) {
                fprintf(stderr, "Input must be UTF-8.\n");
                return 2;
            }
            [urls addObject:[NSURL fileURLWithPath:path.stringByExpandingTildeInPath]];
        }
        puts(QMSmartZipArchiveBaseName(urls).UTF8String);
    }
    return 0;
}
