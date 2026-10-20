#import "../../Utils.h"
#import "../../InstagramHeaders.h"

// Search results only show the accounts tab (no For you, audio, tags, places or reels)
%hook IGSearchContainerSerpViewController
- (void)viewDidLoad {
    if ([SCIUtils getExperimentalPref:@"search_accounts_only"]) {
        MSHookIvar<BOOL>(self, "_swipingDisabled") = YES;
    }

    %orig;

    if ([SCIUtils getExperimentalPref:@"search_accounts_only"]) {
        self.tabControl.hidden = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    if (![SCIUtils getExperimentalPref:@"search_accounts_only"]) return;

    id accountsVC = MSHookIvar<id>(self, "_userSearchSerpViewController");
    NSUInteger index = [MSHookIvar<NSArray *>(self, "_contentViewControllers") indexOfObject:accountsVC];
    if (!accountsVC || index == NSNotFound || [self currentViewController] == accountsVC) return;

    NSLog(@"[SCInsta] Search: switching to accounts tab");

    // Same path as tapping the tab, so the accounts page runs the search
    [self tabBarControlType:self.tabControl tappedSegmentIndex:index];
}
%end

// Search suggestions only show accounts (no keywords/topics)
%hook IGSearchListKitDataSource
- (id)objectsForListAdapter:(id)arg1 {
    NSArray *originalObjs = %orig;
    if (![SCIUtils getExperimentalPref:@"search_accounts_only"]) return originalObjs;

    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:[originalObjs count]];
    for (id obj in originalObjs) {
        if ([obj isKindOfClass:%c(IGSearchResultNestedGroupViewModel)]) continue;

        if ([obj isKindOfClass:%c(IGSearchResultViewModel)] && ![[obj searchableItem] isKindOfClass:%c(IGUser)]) {
            NSLog(@"[SCInsta] Search: hiding non-account suggestion");
            continue;
        }

        [filteredObjs addObject:obj];
    }

    return [filteredObjs copy];
}
%end
