// Copyright (c) 2026 linhy413.
// SPDX-License-Identifier: AGPL-3.0-only
// Section 7 attribution and origin terms: see ATTRIBUTION.md.
// Official project: https://github.com/linhy413/FasterMac

#import "QMSmartZipNaming.h"

NSString *QMSmartZipFinderSelectionScript(void) {
    return @"on run argv\n"
            "if (count of argv) is 0 then return \"cleared\"\n"
            "set resultItems to {}\n"
            "repeat with resultPath in argv\n"
            "set end of resultItems to (POSIX file (resultPath as text)) as alias\n"
            "end repeat\n"
            "tell application \"Finder\"\n"
            "activate\n"
            "set selection to {}\n"
            "reveal (item 1 of resultItems)\n"
            "delay 0.08\n"
            "set selection to resultItems\n"
            "repeat with attemptNumber from 1 to 4\n"
            "delay 0.08\n"
            "set selectedItems to selection\n"
            "if (count of selectedItems) is (count of resultItems) then\n"
            "set allSelected to true\n"
            "repeat with resultItem in resultItems\n"
            "set foundResult to false\n"
            "repeat with selectedItem in selectedItems\n"
            "try\n"
            "if (selectedItem as alias) is (resultItem as alias) then set foundResult to true\n"
            "end try\n"
            "end repeat\n"
            "if foundResult is false then set allSelected to false\n"
            "end repeat\n"
            "if allSelected then return \"selected\"\n"
            "end if\n"
            "if attemptNumber is less than 4 then set selection to resultItems\n"
            "end repeat\n"
            "return \"unverified\"\n"
            "end tell\n"
            "end run";
}

static NSString *QMStemForURL(NSURL *url) {
    NSString *name = url.lastPathComponent ?: @"";
    NSNumber *isDirectory = nil;
    [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
    if (!isDirectory.boolValue && !url.hasDirectoryPath && url.pathExtension.length > 0) {
        NSString *lowercaseName = name.lowercaseString;
        name = name.stringByDeletingPathExtension;
        if ([lowercaseName hasSuffix:@".tar.gz"] ||
            [lowercaseName hasSuffix:@".tar.bz2"] ||
            [lowercaseName hasSuffix:@".tar.xz"]) {
            name = name.stringByDeletingPathExtension;
        }
    }
    return name;
}

static NSString *QMCanonicalToken(NSString *token) {
    return token.precomposedStringWithCanonicalMapping.lowercaseString;
}

static NSArray<NSString *> *QMTokensForStem(NSString *stem) {
    static NSCharacterSet *separators = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *set = NSCharacterSet.whitespaceAndNewlineCharacterSet.mutableCopy;
        [set addCharactersInString:@"_-–—.,;:·/\\()[]{}<>《》【】（）「」『』+"];
        separators = set.copy;
    });

    NSMutableArray<NSString *> *tokens = NSMutableArray.array;
    for (NSString *part in [stem componentsSeparatedByCharactersInSet:separators]) {
        NSString *token = [part stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (token.length > 0) {
            [tokens addObject:token];
        }
    }
    return tokens;
}

static BOOL QMTokenIsOnlyDigits(NSString *token) {
    if (token.length == 0) { return NO; }
    return [token rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet.invertedSet].location == NSNotFound;
}

static BOOL QMTokenIsNoise(NSString *token) {
    if (token.length == 0) { return YES; }
    if (QMTokenIsOnlyDigits(token)) {
        NSInteger number = token.integerValue;
        return !(token.length == 4 && number >= 1900 && number <= 2100);
    }

    static NSRegularExpression *versionPattern = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        versionPattern = [NSRegularExpression regularExpressionWithPattern:@"^(?:v|ver|version|copy|副本)[-_ ]?\\d+$"
                                                                   options:NSRegularExpressionCaseInsensitive
                                                                     error:nil];
    });
    NSRange wholeToken = NSMakeRange(0, token.length);
    return [versionPattern firstMatchInString:token options:0 range:wholeToken] != nil;
}

static NSString *QMCleanArchiveName(NSString *candidate) {
    if (candidate.length == 0) { return @""; }

    NSString *cleaned = [candidate stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    cleaned = [cleaned stringByReplacingOccurrencesOfString:@":" withString:@"-"];

    NSMutableCharacterSet *edgeCharacters = NSCharacterSet.whitespaceAndNewlineCharacterSet.mutableCopy;
    [edgeCharacters addCharactersInString:@"._-–—,;:·+()[]{}<>《》【】（）「」『』"];
    cleaned = [cleaned stringByTrimmingCharactersInSet:edgeCharacters];

    static NSRegularExpression *repeatedWhitespace = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        repeatedWhitespace = [NSRegularExpression regularExpressionWithPattern:@"\\s+" options:0 error:nil];
    });
    cleaned = [repeatedWhitespace stringByReplacingMatchesInString:cleaned
                                                            options:0
                                                              range:NSMakeRange(0, cleaned.length)
                                                       withTemplate:@" "];

    if (cleaned.length > 64) {
        NSRange safeRange = [cleaned rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, 64)];
        cleaned = [cleaned substringWithRange:safeRange];
        cleaned = [cleaned stringByTrimmingCharactersInSet:edgeCharacters];
    }
    if ([cleaned isEqualToString:@"."] || [cleaned isEqualToString:@".."] || [cleaned hasPrefix:@"."]) {
        return @"";
    }
    return cleaned;
}

static NSString *QMCommonStemPrefix(NSArray<NSString *> *stems) {
    if (stems.count == 0) { return @""; }
    NSString *prefix = stems.firstObject;
    for (NSString *stem in stems) {
        prefix = [prefix commonPrefixWithString:stem options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
        if (prefix.length == 0) { return @""; }
    }

    // Sequential names often leave a partial numeric suffix (IMG_001 / IMG_002
    // -> IMG_00). Strip that suffix before evaluating the prefix.
    while (prefix.length > 0) {
        NSRange lastRange = [prefix rangeOfComposedCharacterSequenceAtIndex:prefix.length - 1];
        NSString *lastCharacter = [prefix substringWithRange:lastRange];
        if ([lastCharacter rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet].location == NSNotFound) {
            break;
        }
        prefix = [prefix substringToIndex:lastRange.location];
    }
    return QMCleanArchiveName(prefix);
}

NSString *QMSmartZipArchiveBaseName(NSArray<NSURL *> *urls) {
    if (urls.count == 0) { return @"Archive"; }

    NSMutableArray<NSString *> *stems = NSMutableArray.array;
    for (NSURL *url in urls) {
        NSString *stem = QMCleanArchiveName(QMStemForURL(url));
        if (stem.length > 0) { [stems addObject:stem]; }
    }
    if (stems.count == 0) { return @"Archive"; }
    if (urls.count == 1) { return stems.firstObject; }

    NSMutableArray<NSArray<NSString *> *> *tokenLists = NSMutableArray.array;
    NSMutableDictionary<NSString *, NSNumber *> *frequencies = NSMutableDictionary.dictionary;
    for (NSString *stem in stems) {
        NSArray<NSString *> *tokens = QMTokensForStem(stem);
        [tokenLists addObject:tokens];
        NSMutableSet<NSString *> *seenInStem = NSMutableSet.set;
        for (NSString *token in tokens) {
            if (QMTokenIsNoise(token)) { continue; }
            NSString *key = QMCanonicalToken(token);
            if ([seenInStem containsObject:key]) { continue; }
            [seenInStem addObject:key];
            frequencies[key] = @(frequencies[key].integerValue + 1);
        }
    }

    NSInteger maximumFrequency = 0;
    for (NSNumber *count in frequencies.allValues) {
        maximumFrequency = MAX(maximumFrequency, count.integerValue);
    }

    NSMutableSet<NSString *> *candidateKeys = NSMutableSet.set;
    NSInteger majorityThreshold = urls.count / 2 + 1;
    if (maximumFrequency >= majorityThreshold) {
        for (NSString *key in frequencies) {
            if (frequencies[key].integerValue >= majorityThreshold) {
                [candidateKeys addObject:key];
            }
        }
    } else if (maximumFrequency >= 2) {
        // A repeated field can still be the strongest signal in a large,
        // heterogeneous selection. Use one best field to avoid combining
        // unrelated ties that never occur together.
        NSArray<NSString *> *ties = [frequencies keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber *first, NSNumber *second) {
            return [second compare:first];
        }];
        NSString *bestKey = nil;
        for (NSString *key in ties) {
            if (frequencies[key].integerValue != maximumFrequency) { break; }
            if (!bestKey || key.length > bestKey.length ||
                (key.length == bestKey.length && [key localizedStandardCompare:bestKey] == NSOrderedAscending)) {
                bestKey = key;
            }
        }
        if (bestKey) { [candidateKeys addObject:bestKey]; }
    }

    if (candidateKeys.count > 0) {
        NSArray<NSString *> *representativeTokens = nil;
        NSInteger bestCandidateCount = -1;
        NSInteger bestFrequencyScore = -1;
        NSString *bestStem = nil;
        for (NSInteger index = 0; index < tokenLists.count; index++) {
            NSArray<NSString *> *tokens = tokenLists[index];
            NSMutableSet<NSString *> *seen = NSMutableSet.set;
            NSInteger candidateCount = 0;
            NSInteger frequencyScore = 0;
            for (NSString *token in tokens) {
                NSString *key = QMCanonicalToken(token);
                if ([candidateKeys containsObject:key] && ![seen containsObject:key]) {
                    [seen addObject:key];
                    candidateCount++;
                    frequencyScore += frequencies[key].integerValue;
                }
            }
            NSString *stem = stems[index];
            BOOL isBetter = candidateCount > bestCandidateCount ||
                (candidateCount == bestCandidateCount && frequencyScore > bestFrequencyScore) ||
                (candidateCount == bestCandidateCount && frequencyScore == bestFrequencyScore &&
                 (!bestStem || [stem localizedStandardCompare:bestStem] == NSOrderedAscending));
            if (isBetter) {
                representativeTokens = tokens;
                bestCandidateCount = candidateCount;
                bestFrequencyScore = frequencyScore;
                bestStem = stem;
            }
        }

        NSMutableArray<NSString *> *chosen = NSMutableArray.array;
        NSMutableSet<NSString *> *seen = NSMutableSet.set;
        for (NSString *token in representativeTokens) {
            NSString *key = QMCanonicalToken(token);
            if ([candidateKeys containsObject:key] && ![seen containsObject:key]) {
                [chosen addObject:token];
                [seen addObject:key];
            }
        }
        NSString *sharedFields = QMCleanArchiveName([chosen componentsJoinedByString:@" "]);
        if (sharedFields.length > 0) { return sharedFields; }
    }

    NSString *commonPrefix = QMCommonStemPrefix(stems);
    if (commonPrefix.length >= 2) { return commonPrefix; }

    // The fallback must still be derived from an actually selected item. The
    // Finder selection order also makes the result understandable to the user.
    return stems.firstObject;
}
