#import "../../Utils.h"
#import "../../InstagramHeaders.h"

// Hide the reels tab on profiles of accounts that don't follow you back
%hook _TtC14IGProfileSwift21IGProfileTabGenerator
+ (id)generateTabIdentifiersWithUser:(IGUser *)user userSession:(id)session isCurrentUser:(BOOL)isCurrentUser configuration:(id)configuration shouldShowReelsOnboardingTab:(BOOL)showReelsOnboarding hideClipsTab:(BOOL)hideClipsTab hasClipsDrafts:(BOOL)hasClipsDrafts {
    if (!isCurrentUser && !user.followsCurrentUser) {
        NSLog(@"[SCInsta] Hiding reels tab for non-mutual profile");

        hideClipsTab = YES;
    }

    return %orig(user, session, isCurrentUser, configuration, showReelsOnboarding, hideClipsTab, hasClipsDrafts);
}
%end

// Hide videos (incl. reels shared to the grid) from the posts grid of accounts that don't follow you back
%hook IGProfileUserGridFeedViewController
- (id)objectsForListAdapter:(id)arg1 {
    NSArray *originalObjs = %orig;

    IGUser *user = [self user];
    BOOL isCurrentUser = [user.username isEqualToString:[self userSession].user.username];
    if (!user || isCurrentUser || user.followsCurrentUser) return originalObjs;

    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:[originalObjs count]];
    for (id obj in originalObjs) {
        if ([obj isKindOfClass:%c(IGMedia)] && [(IGMedia *)obj video] != nil) {
            NSLog(@"[SCInsta] Hiding video from non-mutual profile grid");
            continue;
        }

        [filteredObjs addObject:obj];
    }

    return [filteredObjs copy];
}
%end
