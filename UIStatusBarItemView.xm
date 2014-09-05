// The purpose of this is to help LibStatusBar search for icons
// In Protean’s search paths/bundles too

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <flipswitch/Flipswitch.h>
#import "Protean.h"

@interface UIStatusBarForegroundStyle : NSObject
- (UIColor*) tintColor;
- (NSString*) expandedNameForImageName: (NSString*) imageName;
- (UIImage*) shadowImageForImage: (UIImage*) img withIdentifier: (NSString*) id forStyle: (int) style withStrength: (float) strength cachesImage: (bool) cache;
@end

@interface UIImage (Protean)
+ (UIImage*)imageNamed:(NSString *)imageName inBundle:(NSBundle*)bundle;
- (UIImage*) _flatImageWithColor: (UIColor*) color;
+(UIImage*)kitImageNamed:(NSString*)name;
@end

@interface UIColor (Protean)
- (NSString*) styleString;
@end

@interface UIStatusBarItemView ()
-(UIStatusBarForegroundStyle*) foregroundStyle;
@end

@interface _UILegibilityImageSet : NSObject
+ (_UILegibilityImageSet*) imageFromImage: (UIImage*) image withShadowImage: (UIImage*) imag_sh;
@property(retain) UIImage * image;
@property(retain) UIImage * shadowImage;
@end


NSMutableDictionary *cache = [NSMutableDictionary dictionary];

// This is... bad... 
// But, it works. Which is what i need. 
// TODO: better hack

UIImage *resizeImage(UIImage *icon)
{
	float maxWidth = 20.0f;
	float maxHeight = 20.0f;
    
	CGSize size = CGSizeMake(maxWidth, maxHeight);
	CGFloat scale = 1.0f;
    
	// the scale logic below was taken from
	// http://developer.appcelerator.com/question/133826/detecting-new-ipad-3-dpi-and-retina
	if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)])
	{
		if ([UIScreen mainScreen].scale > 1.0f) scale = [[UIScreen mainScreen] scale];
		UIGraphicsBeginImageContextWithOptions(size, false, scale);
	}
	else UIGraphicsBeginImageContext(size);
    
	// Resize image to status bar size and center it
	// make sure the icon fits within the bounds
	CGFloat width = MIN(icon.size.width, maxWidth);
	CGFloat height = MIN(icon.size.height, maxHeight);
    
	CGFloat left = MAX((maxWidth-width)/2, 0);
	left = left > (maxWidth/2) ? maxWidth-(maxWidth/2) : left;
    
	CGFloat top = MAX((maxHeight-height)/2, 0);
	top = top > (maxHeight/2) ? maxHeight-(maxHeight/2) : top;
    
	[icon drawInRect:CGRectMake(left, top, width, height)];
	icon = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
	return icon;
}

%hook UIImage
+(id) kitImageNamed:(NSString*)name
{
    CHECK_ENABLED(%orig);

    if (cache[name])
        return cache[name];
    id _tmp = %orig;
    if (_tmp)
        return _tmp;

    NSString *patchedName = name;
    
    if ([name hasPrefix:@"White_"])
        patchedName = [name substringFromIndex:6];
    else if ([name hasPrefix:@"Black_"])
        patchedName = [name substringFromIndex:6];
    else if ([name hasPrefix:@"LockScreen_"])
        patchedName = [name substringFromIndex:11];
        
    if ([patchedName hasSuffix:@"_Color"])
    return nil;
        //patchedName = [patchedName substringToIndex:patchedName.length - 6];
        
    NSString *patchedName2 = patchedName;
    if ([patchedName hasPrefix:@"PR_"])
        patchedName2 = [patchedName substringFromIndex:3];
    if ([[FSSwitchPanel sharedPanel].switchIdentifiers containsObject:patchedName2])
    {
        BOOL isPad = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
        NSString *TemplatePath = isPad ? @"/Library/Protean/FlipswitchTemplates/IconTemplate~iPad.bundle" : @"/Library/Protean/FlipswitchTemplates/IconTemplate.bundle";
        static NSBundle *templateBundle = nil;
        if (!templateBundle) templateBundle = [NSBundle bundleWithPath:TemplatePath];
        name = [NSString stringWithFormat:@"%@-%@",patchedName2,[[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:patchedName2]==FSSwitchStateOn?@"on":@"off"];
        cache[name] = resizeImage([[[FSSwitchPanel sharedPanel] imageOfSwitchState:[[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:patchedName2] controlState:UIControlStateNormal forSwitchIdentifier:patchedName2 usingTemplate:templateBundle] _flatImageWithColor:[UIColor blackColor]]);
        return cache[name];
    }

    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.png", @"/Library/Protean/Images.bundle", patchedName]];

    if (!image)
    {
        image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/Frameworks/UIKit.framework/%@.png",name]];
    }

    if (image)
        cache[name] = image;

    return image;
}
%end

%hook UIStatusBarIndicatorItemView
-(_UILegibilityImageSet*) contentsImage
{
	UIStatusBarForegroundStyle* fs = [self foregroundStyle];
	UIColor* tintColor = [fs tintColor];
	int type = ((UIStatusBarItemView*)self).item.type;
	NSString* itemName = [Protean imageNameForIdentifier:[NSString stringWithFormat:@"%d",type]];

	if (itemName == nil || [itemName isEqual:@""])
		return %orig;

	NSString* expandedName_default = [fs expandedNameForImageName: itemName];
	
	bool isBlack = [tintColor isEqual: [UIColor blackColor]];
	bool isLockscreen = [fs isKindOfClass:objc_getClass("UIStatusBarLockScreenForegroundStyleAttributes")];
	
	UIImage* image_color = [UIImage kitImageNamed: [NSString stringWithFormat: @"%@_%@_Color", isLockscreen?  @"LockScreen" : isBlack ? @"Black" : @"White", itemName]];
	UIImage* image_base = image_color ? 0 : [UIImage kitImageNamed: expandedName_default];
	
	UIImage* image = image_color;
	if(!image && image_base)
	{
		image = [image_base _flatImageWithColor: tintColor];
	}
	_UILegibilityImageSet* ret = [_UILegibilityImageSet imageFromImage: image withShadowImage: nil];//image_sh];
	
	return ret;

}
%end

%hook UIStatusBarQuietModeItemView
-(_UILegibilityImageSet*) contentsImage
{
	UIStatusBarForegroundStyle* fs = [self foregroundStyle];
	UIColor* tintColor = [fs tintColor];
	int type = ((UIStatusBarItemView*)self).item.type;
	NSString* itemName = [Protean imageNameForIdentifier:[NSString stringWithFormat:@"%d",type]];

	if (itemName == nil || [itemName isEqual:@""])
		return %orig;

	NSString* expandedName_default = [fs expandedNameForImageName: itemName];
	
	bool isBlack = [tintColor isEqual: [UIColor blackColor]];
	bool isLockscreen = [fs isKindOfClass:objc_getClass("UIStatusBarLockScreenForegroundStyleAttributes")];
	
	UIImage* image_color = [UIImage kitImageNamed: [NSString stringWithFormat: @"%@_%@_Color", isLockscreen?  @"LockScreen" : isBlack ? @"Black" : @"White", itemName]];
	UIImage* image_base = image_color ? 0 : [UIImage kitImageNamed: expandedName_default];
	
	UIImage* image = image_color;
	if(!image && image_base)
	{
		image = [image_base _flatImageWithColor: tintColor];
	}
	_UILegibilityImageSet* ret = [_UILegibilityImageSet imageFromImage: image withShadowImage: nil];//image_sh];
	
	return ret;

}
%end

%hook UIStatusBarAirplaneModeItemView
-(_UILegibilityImageSet*) contentsImage
{
	UIStatusBarForegroundStyle* fs = [self foregroundStyle];
	UIColor* tintColor = [fs tintColor];
	int type = ((UIStatusBarItemView*)self).item.type;
	NSString* itemName = [Protean imageNameForIdentifier:[NSString stringWithFormat:@"%d",type]];

	if (itemName == nil || [itemName isEqual:@""])
		return %orig;

	NSString* expandedName_default = [fs expandedNameForImageName: itemName];
	
	bool isBlack = [tintColor isEqual: [UIColor blackColor]];
	bool isLockscreen = [fs isKindOfClass:objc_getClass("UIStatusBarLockScreenForegroundStyleAttributes")];
	
	UIImage* image_color = [UIImage kitImageNamed: [NSString stringWithFormat: @"%@_%@_Color", isLockscreen?  @"LockScreen" : isBlack ? @"Black" : @"White", itemName]];
	UIImage* image_base = image_color ? 0 : [UIImage kitImageNamed: expandedName_default];
	
	UIImage* image = image_color;
	if(!image && image_base)
	{
		image = [image_base _flatImageWithColor: tintColor];
	}
	_UILegibilityImageSet* ret = [_UILegibilityImageSet imageFromImage: image withShadowImage: nil];//image_sh];
	
	return ret;

}
%end

%hook UIStatusBarBluetoothItemView
-(_UILegibilityImageSet*) contentsImage
{
	UIStatusBarForegroundStyle* fs = [self foregroundStyle];
	UIColor* tintColor = [fs tintColor];
	int type = ((UIStatusBarItemView*)self).item.type;
	NSString* itemName = [Protean imageNameForIdentifier:[NSString stringWithFormat:@"%d",type]];

	if (itemName == nil || [itemName isEqual:@""])
		return %orig;

	NSString* expandedName_default = [fs expandedNameForImageName: itemName];
	
	bool isBlack = [tintColor isEqual: [UIColor blackColor]];
	bool isLockscreen = [fs isKindOfClass:objc_getClass("UIStatusBarLockScreenForegroundStyleAttributes")];
	
	UIImage* image_color = [UIImage kitImageNamed: [NSString stringWithFormat: @"%@_%@_Color", isLockscreen?  @"LockScreen" : isBlack ? @"Black" : @"White", itemName]];
	UIImage* image_base = image_color ? 0 : [UIImage kitImageNamed: expandedName_default];
	
	UIImage* image = image_color;
	if(!image && image_base)
	{
		image = [image_base _flatImageWithColor: tintColor];
	}
	_UILegibilityImageSet* ret = [_UILegibilityImageSet imageFromImage: image withShadowImage: nil];//image_sh];
	
	return ret;

}
%end

%hook UIStatusBarLocationItemView
-(_UILegibilityImageSet*) contentsImage
{
	UIStatusBarForegroundStyle* fs = [self foregroundStyle];
	UIColor* tintColor = [fs tintColor];
	int type = ((UIStatusBarItemView*)self).item.type;
	NSString* itemName = [Protean imageNameForIdentifier:[NSString stringWithFormat:@"%d",type]];

	if (itemName == nil || [itemName isEqual:@""])
		return %orig;

	NSString* expandedName_default = [fs expandedNameForImageName: itemName];
	
	bool isBlack = [tintColor isEqual: [UIColor blackColor]];
	bool isLockscreen = [fs isKindOfClass:objc_getClass("UIStatusBarLockScreenForegroundStyleAttributes")];
	
	UIImage* image_color = [UIImage kitImageNamed: [NSString stringWithFormat: @"%@_%@_Color", isLockscreen?  @"LockScreen" : isBlack ? @"Black" : @"White", itemName]];
	UIImage* image_base = image_color ? 0 : [UIImage kitImageNamed: expandedName_default];
	
	UIImage* image = image_color;
	if(!image && image_base)
	{
		image = [image_base _flatImageWithColor: tintColor];
	}
	_UILegibilityImageSet* ret = [_UILegibilityImageSet imageFromImage: image withShadowImage: nil];//image_sh];
	
	return ret;

}
%end
