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
    id time = [Protean getOrLoadSettings][@"0"];
    int alignment = time && time[@"alignment"] ? [time[@"alignment"] intValue] : 4;
    if ((item ? [item boolValue] : YES) || (alignment == 0 || alignment == 1))
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
    id time = [Protean getOrLoadSettings][@"0"];
    int alignment = time && time[@"alignment"] ? [time[@"alignment"] intValue] : 4;
    if ((item ? [item boolValue] : YES) || (alignment == 0 || alignment == 1))
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
    id time = [Protean getOrLoadSettings][@"0"];
    int alignment = time && time[@"alignment"] ? [time[@"alignment"] intValue] : 4;
    if ((item ? [item boolValue] : YES) || (alignment == 0 || alignment == 1))
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
    id time = [Protean getOrLoadSettings][@"0"];
    int alignment = time && time[@"alignment"] ? [time[@"alignment"] intValue] : 4;
    if ((item ? [item boolValue] : YES) || (alignment == 0 || alignment == 1))
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
    id time = [Protean getOrLoadSettings][@"0"];
    int alignment = time && time[@"alignment"] ? [time[@"alignment"] intValue] : 4;
    if ((item ? [item boolValue] : YES) || (alignment == 0 || alignment == 1))
    {
        %orig(YES, arg2);
        return;
    }
    
    %orig;
}
//- (_Bool)isTopGrabberHidden;
%end

/*
%ctor
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/LockPages.dylib"])
    {
        int numClasses = objc_getClassList(NULL, 0);

        Class* list = (Class*)malloc(sizeof(Class) * numClasses);
        objc_getClassList(list, numClasses);

        for (int i = 0; i < numClasses; i++)
        {
            IMP orig$isTimeEnabled = NULL;
            
            BOOL (^new$isTimeEnabled)(id, SEL) = ^BOOL(id self, SEL _cmd) {
                id item = [Protean getOrLoadSettings][@"showLSTime"];
                id time = [Protean getOrLoadSettings][@"0"];
                int alignment = time && time[@"alignment"] ? [time[@"alignment"] intValue] : 4;
                if ((item ? [item boolValue] : YES) || (alignment == 0 || alignment == 1))
                    return YES;
                else
                    return [orig$isTimeEnabled(self, _cmd) boolValue];
            };

            if (class_conformsToProtocol(list[i], @protocol(LPPage)) &&
                class_getInstanceMethod(list[i], @selector(isTimeEnabled)))
            {
                MSHookMessageEx(list[i], @selector(isTimeEnabled), (IMP)new$isTimeEnabled, (IMP*)&orig$isTimeEnabled);
            }
        }
        free(list);
    }
}
*/