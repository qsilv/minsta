#import "../../Utils.h"
#import "../../InstagramHeaders.h"

// Search results only show the accounts tab (no For you, audio, tags, places or reels)
%hook IGSearchContainerSerpViewController
- (void)viewDidLoad {
    MSHookIvar<BOOL>(self, "_swipingDisabled") = YES;

    %orig;

    id accountsVC = MSHookIvar<id>(self, "_userSearchSerpViewController");
    NSArray *pages = MSHookIvar<NSArray *>(self, "_contentViewControllers");
    if (!accountsVC || ![pages containsObject:accountsVC]) return;

    NSLog(@"[SCInsta] Search: showing accounts tab only");

    [self setCurrentViewController:accountsVC];
    self.tabControl.hidden = YES;
}
%end
