#import "Protean.h"
#import <objc/runtime.h>

@protocol LPPage
-(BOOL) isTimeEnabled;
@end

%hook SBLockScreenViewController
-(BOOL)shouldShowLockStatusBarTime
{
    CHECK_ENABLED(%orig);

    id item = [Protean getOrLoadSettings][@"showLSTime"];
    //id time = [Protean getOrLoadSettings][@"0"];
    //int alignment = time && time[@"alignment"] ? [time[@"alignment"] intValue] : 4;
    if ((item ? [item boolValue] : YES)) //  || (alignment == 0 || alignment == 1)
        return YES;
    else
        return %orig;
}
%end

%hook LITodayPage
-(BOOL)isTimeEnabled
{
    CHECK_ENABLED(%orig);

    id item = [Protean getOrLoadSettings][@"showLSTime"];
    if ((item ? [item boolValue] : YES))
        return YES;
    else
        return %orig;
}
%end

%hook LINotificationsPage
-(BOOL)isTimeEnabled
{
    CHECK_ENABLED(%orig);

    id item = [Protean getOrLoadSettings][@"showLSTime"];
    if ((item ? [item boolValue] : YES))
        return YES;
    else
        return %orig;
}
%end

%hook FCForecastViewController
-(BOOL)isTimeEnabled
{
    CHECK_ENABLED(%orig);

    id item = [Protean getOrLoadSettings][@"showLSTime"];
    if ((item ? [item boolValue] : YES))
        return YES;
    else
        return %orig;
}
%end

%hook SBLockScreenView
- (void)setTopGrabberHidden:(_Bool)arg1 forRequester:(id)arg2
{
    CHECK_ENABLED2(%orig);

    id item = [Protean getOrLoadSettings][@"showLSTime"];
    if ((item ? [item boolValue] : YES))
    {
        %orig(YES, arg2);
        return;
    }
    
    %orig;
}
//- (_Bool)isTopGrabberHidden;
%end

