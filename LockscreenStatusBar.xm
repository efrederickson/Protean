#import "Protean.h"

%hook SBLockScreenViewController
//-(int)statusBarStyle
//{
//    return 0;
//}

- (NSInteger)statusBarStyle
{
    CHECK_ENABLED(%orig);

	id item = [Protean getOrLoadSettings][@"normalizeLS"];
	
    if (item ? [item boolValue] : YES)
        return 0;
    
    return %orig;
}

%end

%ctor
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(){
        %init;
    });
}

