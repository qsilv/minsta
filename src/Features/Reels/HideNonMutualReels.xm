#import "../../Utils.h"
#import "../../InstagramHeaders.h"

// Reels opened from the profile of an account that doesn't follow you back get closed.
// Reels opened anywhere else (e.g. sent to you in DMs) are left alone.

static BOOL profileFollowsBack(UIViewController *profileVC) {
    IGUser *user = nil;
    @try { user = [[profileVC valueForKey:@"_bioModel"] valueForKey:@"user"]; } @catch (id e) {}
    if (!user) {
        @try { user = [profileVC valueForKey:@"user"]; } @catch (id e) {}
    }

    // Can't tell whose profile this is, so block it
    if (!user) return NO;

    // Own profile
    if ([profileVC.view.window isKindOfClass:%c(IGWindow)]) {
        NSString *me = ((IGWindow *)profileVC.view.window).userSession.user.username;
        if (me && [user.username isEqualToString:me]) return YES;
    }

    return user.followsCurrentUser;
}

// The screen the reels viewer was opened from
static UIViewController *openedFrom(UIViewController *vc) {
    NSArray *stack = vc.navigationController.viewControllers;
    NSUInteger index = [stack indexOfObject:vc];
    if (index != NSNotFound && index > 0) return stack[index - 1];

    UIViewController *presenter = vc.navigationController.presentingViewController ?: vc.presentingViewController;
    while ([presenter isKindOfClass:[UINavigationController class]]) {
        presenter = ((UINavigationController *)presenter).topViewController;
    }
    return presenter;
}

%hook IGSundialFeedViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;

    UIViewController *source = openedFrom(self);
    if (![source isKindOfClass:%c(IGProfileViewController)] || profileFollowsBack(source)) return;

    NSLog(@"[SCInsta] Blocking reels from non-mutual profile");

    NSArray *stack = self.navigationController.viewControllers;
    if (stack.count > 1 && [stack indexOfObject:self] != NSNotFound) {
        [self.navigationController popViewControllerAnimated:NO];
    }
    else {
        [(self.navigationController ?: self) dismissViewControllerAnimated:NO completion:nil];
    }

    [SCIUtils showErrorHUDWithDescription:@"Reels are hidden for accounts that don't follow you back"];
}
%end
