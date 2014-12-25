#import "PRStatusApps.h"
#import "Protean.h"
#import <flipswitch/Flipswitch.h>

%group SpringBoard
%hook FSSwitchMainPanel

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier
{
    FSSwitchState ret = %orig;
    CHECK_ENABLED(ret);

    id enabled_ = [Protean getOrLoadSettings][@"flipswitches"][switchIdentifier];
    BOOL enabled = enabled_ ? [enabled_ boolValue] : NO;
    id alwaysShow_ = [Protean getOrLoadSettings][@"alwaysShowFlipswitches"][switchIdentifier];
    BOOL alwaysShow = alwaysShow_ ? [alwaysShow_ boolValue] : NO;
    id showWhenOff_ = [Protean getOrLoadSettings][@"showWhenOffFlipswitches"][switchIdentifier];
    BOOL showWhenOff = showWhenOff_ ? [showWhenOff_ boolValue] : NO;

    if (enabled && ((ret == FSSwitchStateOn && showWhenOff == NO) || alwaysShow || (ret == FSSwitchStateOff && showWhenOff)))
    {
        [PRStatusApps showIconForFlipswitch:switchIdentifier];
    }
    else
        [PRStatusApps hideIconFor:switchIdentifier];

    return ret;
}

- (void)setState:(FSSwitchState)state forSwitchIdentifier:(NSString *)switchIdentifier
{
    %orig;
    CHECK_ENABLED();

    id enabled_ = [Protean getOrLoadSettings][@"flipswitches"][switchIdentifier];
    BOOL enabled = enabled_ ? [enabled_ boolValue] : NO;
    id alwaysShow_ = [Protean getOrLoadSettings][@"alwaysShowFlipswitches"][switchIdentifier];
    BOOL alwaysShow = alwaysShow_ ? [alwaysShow_ boolValue] : NO;
    id showWhenOff_ = [Protean getOrLoadSettings][@"showWhenOffFlipswitches"][switchIdentifier];
    BOOL showWhenOff = showWhenOff_ ? [showWhenOff_ boolValue] : NO;

    if (enabled && ((state == FSSwitchStateOn && showWhenOff == NO) || alwaysShow || (state == FSSwitchStateOff && showWhenOff)))
    {
        [PRStatusApps showIconForFlipswitch:switchIdentifier];
    }
    else
        [PRStatusApps hideIconFor:switchIdentifier];

}

- (void)stateDidChangeForSwitchIdentifier:(NSString *)switchIdentifier
{
    %orig;
    CHECK_ENABLED();

    FSSwitchState state = [[objc_getClass("FSSwitchMainPanel") sharedPanel] stateForSwitchIdentifier:switchIdentifier];
    id enabled_ = [Protean getOrLoadSettings][@"flipswitches"][switchIdentifier];
    BOOL enabled = enabled_ ? [enabled_ boolValue] : NO;
    id alwaysShow_ = [Protean getOrLoadSettings][@"alwaysShowFlipswitches"][switchIdentifier];
    BOOL alwaysShow = alwaysShow_ ? [alwaysShow_ boolValue] : NO;
    id showWhenOff_ = [Protean getOrLoadSettings][@"showWhenOffFlipswitches"][switchIdentifier];
    BOOL showWhenOff = showWhenOff_ ? [showWhenOff_ boolValue] : NO;

    if (enabled && ((state == FSSwitchStateOn && showWhenOff == NO) || alwaysShow || (state == FSSwitchStateOff && showWhenOff)))
    {
        [PRStatusApps showIconForFlipswitch:switchIdentifier];
    }
    else
        [PRStatusApps hideIconFor:switchIdentifier];
}
%end
%end

UIImage *resizeImage(UIImage *icon)
{
    CGSize size = icon.size;
    CGFloat scale = 10 / size.height;
    size.height *= scale;
    size.width *= scale;

    size.height *= 1.4;
    size.width *= 1.4;

    UIGraphicsBeginImageContextWithOptions(size, false, [[UIScreen mainScreen] scale]);
    [icon drawInRect:CGRectMake(0, 0, size.width, size.height)];
    icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return icon;
}

%ctor
{
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqual:@"com.apple.springboard"])
    {
        %init(SpringBoard);

        [NSFileManager.defaultManager createDirectoryAtPath:@"/User/Library/Protean/protean-fscache" withIntermediateDirectories:YES attributes:nil error:nil];
        for (NSString *switchIdentifier in FSSwitchPanel.sharedPanel.switchIdentifiers)
        {
            NSBundle *templateBundle = nil;
            if (!templateBundle) 
                templateBundle = [NSBundle bundleWithPath:@"/Library/Protean/FlipswitchTemplates/IconTemplate.bundle"];

            UIImage *img = [[FSSwitchPanel sharedPanel] 
                imageOfSwitchState:FSSwitchStateOff
                controlState:UIControlStateNormal forSwitchIdentifier:switchIdentifier usingTemplate:templateBundle];
            NSString *filePath = nil;
            if (UIScreen.mainScreen.scale > 1)
                filePath = [NSString stringWithFormat:@"/User/Library/Protean/protean-fscache/%@-off@%.0fx.png",switchIdentifier, UIScreen.mainScreen.scale];
            else
                filePath = [NSString stringWithFormat:@"/User/Library/Protean/protean-fscache/%@-off.png",switchIdentifier];

            [UIImagePNGRepresentation(resizeImage(img)) writeToFile:filePath atomically:YES];

            img = [[FSSwitchPanel sharedPanel] 
                imageOfSwitchState:FSSwitchStateOn
                controlState:UIControlStateNormal forSwitchIdentifier:switchIdentifier usingTemplate:templateBundle];
            if (UIScreen.mainScreen.scale > 1)
                filePath = [NSString stringWithFormat:@"/User/Library/Protean/protean-fscache/%@-on@%.0fx.png",switchIdentifier, UIScreen.mainScreen.scale];
            else
                filePath = [NSString stringWithFormat:@"/User/Library/Protean/protean-fscache/%@-on.png",switchIdentifier];

            [UIImagePNGRepresentation(resizeImage(img)) writeToFile:filePath atomically:YES];
        }
    }
}