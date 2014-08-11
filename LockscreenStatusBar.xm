#import "Protean.h"

%hook SBLockScreenViewController
//-(int)statusBarStyle
//{
//    return 0;
//}

- (long long)statusBarStyle
{
    CHECK_ENABLED(%orig);

	id item = [Protean getOrLoadSettings][@"normalizeLS"];
	
    if (item ? [item boolValue] : YES)
        return 0;
        
    return %orig;
}
%end