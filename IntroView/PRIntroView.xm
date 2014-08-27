#import "PRViewController.h"
#import "../Protean.h"
#import "PRFinalViewController.h"

#define PLIST_NAME @"/var/mobile/Library/Preferences/com.efrederickson.protean.settings.plist"

@interface SBLockStateAggregator
+(id)sharedInstance;
-(void)_updateLockState;
-(BOOL)hasAnyLockState;
-(unsigned)lockState;
@end

UIWindow *window;

%hook SBLockStateAggregator

-(void)_updateLockState
{
    %orig;

    if ([self hasAnyLockState])
        return;
        
    //if ([[Protean getOrLoadSettings][@"hasShownIntro"] boolValue] == YES)
    //    return;
        
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:PLIST_NAME];
    dict[@"hasShownIntro"] = @YES;
    [dict writeToFile:PLIST_NAME atomically:YES];
    [Protean reloadSettings];

    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIViewController *viewController = [[/*PRViewController*/PRFinalViewController alloc] init];
    window.rootViewController = viewController;

    [window makeKeyAndVisible];
}
%end

%hook SpringBoard
%new
-(void) PR_HideIntro
{
    [UIView animateWithDuration:.5 animations:^{
        //window.alpha = 0.1;
        window.frame = CGRectMake(window.frame.origin.x, [UIScreen mainScreen].bounds.size.height,
                                      window.frame.size.width, window.frame.size.height);
    } completion:^(BOOL finished) {  
        [window release];
        window = nil;
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Protean"]];
    }];


}

%end
