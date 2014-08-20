#import "Protean.h"

@class _UILegibilityImageSet;

@interface UIStatusBarSignalStrengthItemView : UIStatusBarItemView {
    int _signalStrengthRaw;
    int _signalStrengthBars;
    BOOL _enableRSSI;
    BOOL _showRSSI;
}

- (NSString *)_stringForRSSI;
- (_UILegibilityImageSet *)contentsImage;
- (BOOL)updateForNewData:(id)arg1 actions:(int)arg2;
- (void)touchesEnded:(id)arg1 withEvent:(id)arg2;
@end

%hook UIStatusBarSignalStrengthItemView
- (_UILegibilityImageSet *)contentsImage
{
    CHECK_ENABLED(%orig);
	
    id showRSSI = [Protean getOrLoadSettings][@"showSignalRSSI"];
    if (showRSSI && [showRSSI boolValue])
    {
		return [self imageWithText:[self _stringForRSSI]];
	}
    
    return %orig;
}
%end
