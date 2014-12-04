#import "headers.h"

@interface UIStatusBarSignalStrengthItemView : UIStatusBarItemView {
    BOOL _enableRSSI;
    BOOL _showRSSI;
    int _signalStrengthBars;
    int _signalStrengthRaw;
}

- (id)_stringForRSSI;
- (id)contentsImage;
- (float)extraRightPadding;
- (void)touchesEnded:(id)arg1 withEvent:(id)arg2;
- (BOOL)updateForNewData:(id)arg1 actions:(int)arg2;

@end

@interface _UILegibilityImageSet : NSObject
+ (_UILegibilityImageSet*) imageFromImage: (UIImage*) image withShadowImage: (UIImage*) imag_sh;
@property(retain) UIImage * image;
@property(retain) UIImage * shadowImage;
@end


%hook UIStatusBarSignalStrengthItemView
-(_UILegibilityImageSet*) contentsImage
{

}
%end