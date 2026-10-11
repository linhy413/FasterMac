// Copyright (c) 2026 linhy413.
// SPDX-License-Identifier: AGPL-3.0-only
// Section 7 attribution and origin terms: see ATTRIBUTION.md.
// Official project: https://github.com/linhy413/FasterMac

#import <Foundation/Foundation.h>
#import "Actions/QMSmartZipNaming.h"

static NSArray<NSURL *> *URLs(NSArray<NSString *> *paths) {
    NSMutableArray<NSURL *> *urls = NSMutableArray.array;
    for (NSString *path in paths) {
        [urls addObject:[NSURL fileURLWithPath:path]];
    }
    return urls;
}

static void AssertName(NSArray<NSString *> *paths, NSString *expected) {
    NSString *actual = QMSmartZipArchiveBaseName(URLs(paths));
    NSCAssert([actual isEqualToString:expected], @"expected '%@', got '%@'", expected, actual);
}

int main(void) {
    @autoreleasepool {
        NSDictionary *scriptError = nil;
        NSAppleScript *selectionScript = [[NSAppleScript alloc] initWithSource:QMSmartZipFinderSelectionScript()];
        NSCAssert([selectionScript compileAndReturnError:&scriptError],
                  @"Finder selection script must compile: %@", scriptError);
        NSString *finderSelectionScript = QMSmartZipFinderSelectionScript();
        NSCAssert([finderSelectionScript containsString:@"set selection to {}"],
                  @"Finder selection script must clear stale source selections");
        NSCAssert([[finderSelectionScript componentsSeparatedByString:@"set selection to {}"] count] - 1 == 1,
                  @"Finder selection must clear stale sources only once");
        NSCAssert([finderSelectionScript rangeOfString:@"set selection to {}"].location <
                  [finderSelectionScript rangeOfString:@"repeat with attemptNumber"].location,
                  @"Finder retries must not repeatedly clear the visible selection");
        NSCAssert([finderSelectionScript containsString:@"repeat with resultPath in argv"],
                  @"Finder selection script must support every requested result");
        NSCAssert([finderSelectionScript containsString:@"if allSelected then return \"selected\""],
                  @"Finder selection script must verify all selected result paths");
        NSCAssert([finderSelectionScript containsString:@"if (selectedItem as alias) is (resultItem as alias)"],
                  @"Finder selection must compare aliases so folder trailing slashes cannot cancel a valid selection");
        NSCAssert(![finderSelectionScript containsString:@"POSIX path of (selectedItem as alias)"],
                  @"Finder selection must not compare folder paths with inconsistent trailing slashes");

        AssertName(@[@"/tmp/项目A-合同-甲方.pdf",
                     @"/tmp/项目A-合同-乙方.docx",
                     @"/tmp/项目A-说明.txt"],
                   @"项目A 合同");

        AssertName(@[@"/tmp/甲方-年度报告.pdf",
                     @"/tmp/乙方-年度报告.docx",
                     @"/tmp/丙方-清单.txt"],
                   @"年度报告");

        AssertName(@[@"/tmp/产品图红.png", @"/tmp/产品图蓝.jpg"], @"产品图");
        AssertName(@[@"/tmp/品牌图_v1_001.jpg", @"/tmp/品牌图_v1_002.png"], @"品牌图");
        AssertName(@[@"/tmp/备份甲.tar.gz", @"/tmp/备份乙.tar.gz"], @"备份");
        AssertName(@[@"/tmp/旅行/猫.jpg", @"/tmp/旅行/狗.png"], @"猫");
        AssertName(@[@"/tmp/发布说明.md"], @"发布说明");

        NSArray<NSString *> *heterogeneous = @[
            @"/tmp/客户提案-甲.pdf", @"/tmp/客户提案-乙.pdf",
            @"/tmp/预算.xlsx", @"/tmp/清单.txt", @"/tmp/说明.md"
        ];
        AssertName(heterogeneous, @"客户提案");
        AssertName(heterogeneous.reverseObjectEnumerator.allObjects, @"客户提案");

        NSLog(@"PASS: SmartZip derives stable representative archive names");
    }
    return 0;
}
