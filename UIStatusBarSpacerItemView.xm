#import "Protean.h"
@interface UIStatusBarItemView ()
-(id) contentsImage;
-(id) imageWithText:(id)arg;
@end

%subclass UIStatusBarSpacerItemView : UIStatusBarCustomItemView
-(id) contentsImage
{
	return [((UIStatusBarItemView*)self) imageWithText:@"|"];
}
%end

%hook UIStatusBarSpacerItemView
- (CGFloat)standardPadding 
{
    CGFloat o = %orig; 

    CHECK_ENABLED(o);
    id padding = [Protean getOrLoadSettings][@"padding"];
    return padding ? [padding floatValue] : o;
}
%end